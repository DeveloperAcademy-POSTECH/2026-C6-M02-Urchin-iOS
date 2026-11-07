//
//  MapView.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import MapKit
import SwiftUI

import ComposableArchitecture

struct MapView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<MapFeature>
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var tappedMarkerID: UUID?
    @State private var mapSize: CGSize = .zero
    @Environment(\.scenePhase) private var scenePhase

    private static let sheetHeight: CGFloat = 400

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mapContent
                .toolbar(.hidden, for: .navigationBar)
        } destination: { store in
            destination(store)
                .toolbar(.hidden, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
        }
        .sheet(item: $store.scope(state: \.beachSheet, action: \.beachSheet)) { store in
            BeachSheetView(store: store)
                .presentationDetents([.height(Self.sheetHeight)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.sheetHeight)))
                .presentationCornerRadius(24)
        }
        .onAppear {
            cameraPosition = Self.cameraPosition(for: store.cameraCommand)
        }
        .onChange(of: store.cameraRevision) {
            withAnimation {
                cameraPosition = Self.cameraPosition(for: store.cameraCommand)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.sceneBecameActive)
            }
        }
        .task {
            store.send(.task)
        }
    }

    @ViewBuilder
    private func destination(_ store: StoreOf<MapFeature.Path>) -> some View {
        switch store.case {
        case let .beachHome(store):
            BeachHomeView(store: store)
        case let .searchBeach(store):
            SearchBeachView(store: store)
        case let .recordDetail(store):
            RecordDetailView(store: store)
        }
    }
}

// MARK: - 지도

private extension MapView {

    var mapContent: some View {
        let markers = store.markers
        let layout = MarkerLayout(
            markers: markers,
            selectedID: store.selectedBeachID,
            region: visibleRegion ?? Self.region(for: store.cameraCommand),
            mapSize: mapSize
        )

        // 마커 탭은 MapKit 선택으로 받아요. 주석 안에 탭 제스처를 다는 것보다 MapKit이 직접 처리해서 더 안정적이에요.
        return Map(position: $cameraPosition, selection: $tappedMarkerID) {
            // 화면 근처에서 보이는 마커(핀, 점)만 지도에 올려요. 숨긴 마커가 투명하게 남아 있으면 그 자리의 탭을 가로채요.
            // MapKit은 주석 뷰의 크기로 탭을 판정해서, 뷰 크기를 그려지는 모양에 딱 맞춰요.
            ForEach(markers.filter { layout.style(for: $0.id) != .hidden }) { marker in
                let style = layout.style(for: marker.id)

                Annotation(marker.beach.name, coordinate: marker.beach.coordinate.location, anchor: style == .pin ? .bottom : .center) {
                    BeachMarkerView(
                        recordCount: marker.recordCount,
                        style: style,
                        isSelected: marker.id == store.selectedBeachID
                    )
                }
                // 이름은 핀에만 보여줘요. MapKit 이름표는 탭 영역에 들어가지 않아요.
                .annotationTitles(style == .pin ? .automatic : .hidden)
                .tag(marker.id)
            }

            if store.isLocationAuthorized {
                UserAnnotation()
            }
        }
        // 확대/축소나 이동이 끝난 뒤에만 마커 규칙을 적용해요. 움직이는 중에 다시 그리면 마커가 많을수록 버벅여요.
        .onMapCameraChange(frequency: .onEnd) { context in
            // 영역이 그대로면 마커를 다시 그리지 않아요. 마커 탭과 다시 그리기가 겹치지 않게 해요.
            guard !MarkerLayout.isSameRegion(visibleRegion, context.region) else { return }
            visibleRegion = context.region
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            mapSize = size
        }
        .onChange(of: tappedMarkerID) { _, id in
            guard let id else { return }
            tappedMarkerID = nil

            // 다른 핀에 가려 숨긴 마커는 탭해도 반응하지 않게 해요.
            guard let marker = markers.first(where: { $0.id == id }),
                  layout.style(for: id) != .hidden
            else { return }
            store.send(.markerTapped(marker))
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                searchBar

                if store.authorization == .denied {
                    locationOffBadge
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .overlay(alignment: .bottomTrailing) {
            currentLocationButton
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
    }

    var searchBar: some View {
        Button {
            store.send(.searchButtonTapped)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.textSecondary))
                    .frame(width: 24, height: 24)

                Text("해변, 해수욕장 이름을 검색해주세요.")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textTertiary))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    var locationOffBadge: some View {
        Button {
            store.send(.locationSettingsTapped)
        } label: {
            HStack(spacing: 4) {
                Text("위치 서비스가 꺼져 있음")
                    .plobbyFont(.helper)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color(.textTertiary))
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color(.gray0), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    var currentLocationButton: some View {
        Button {
            store.send(.currentLocationButtonTapped)
        } label: {
            ZStack {
                if store.isLocating {
                    ProgressView()
                } else {
                    Image(systemName: "scope")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                }
            }
            .frame(width: 44, height: 44)
            .background(Color(.gray0), in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 위치로 이동")
    }
}

// MARK: - Functions

private extension MapView {

    static func cameraPosition(for command: CameraCommand) -> MapCameraPosition {
        .region(region(for: command))
    }

    /// 지도가 아직 위치를 알려주기 전에는 옮기려던 영역을 기준으로 마커를 계산해요.
    static func region(for command: CameraCommand) -> MKCoordinateRegion {
        switch command {
        case let .region(center, meters):
            MKCoordinateRegion(
                center: center.location,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        }
    }
}

// MARK: - MarkerLayout

/// 화면에서 서로 겹치는 핀을 골라 점으로 바꿔요. 선택한 핀, 기록이 많은 핀 순서로 자리를 먼저 차지해요.
/// MapKit은 그리는 순서를 보장하지 않아서, 핀 몸통에 가려질 점은 아예 그리지 않아요.
private struct MarkerLayout {

    /// 핀(배지 포함)이 차지하는 크기. 핀은 좌표 위쪽으로 그려져요.
    static let pinSize = CGSize(width: 68, height: 76)
    /// 핀 아래 해변 이름
    static let labelSize = CGSize(width: 110, height: 20)
    /// 점의 탭 영역
    static let dotSize: CGFloat = 24

    private(set) var pinIDs: Set<UUID> = []
    private(set) var dotIDs: Set<UUID> = []

    static func isSameRegion(_ lhs: MKCoordinateRegion?, _ rhs: MKCoordinateRegion) -> Bool {
        guard let lhs else { return false }
        let tolerance = 1e-9
        return abs(lhs.center.latitude - rhs.center.latitude) < tolerance
            && abs(lhs.center.longitude - rhs.center.longitude) < tolerance
            && abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta) < tolerance
            && abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta) < tolerance
    }

    func style(for id: UUID) -> MarkerStyle {
        if pinIDs.contains(id) { return .pin }
        if dotIDs.contains(id) { return .dot }
        return .hidden
    }

    init(markers: [BeachMarker], selectedID: UUID?, region: MKCoordinateRegion, mapSize: CGSize) {
        // 지도 크기를 알기 전에는 아무것도 그리지 않아요.
        guard mapSize.width > 0, mapSize.height > 0 else { return }

        let pointsPerLongitude = mapSize.width / region.span.longitudeDelta
        let pointsPerLatitude = mapSize.height / region.span.latitudeDelta

        // 화면 밖 핀은 계산에서 빼요. 움직일 때 미리 그려 두도록 화면 크기만큼 여유를 둬요.
        let latitudeRange = (region.center.latitude - region.span.latitudeDelta)...(region.center.latitude + region.span.latitudeDelta)
        let longitudeRange = (region.center.longitude - region.span.longitudeDelta)...(region.center.longitude + region.span.longitudeDelta)

        let ordered = markers
            .filter { latitudeRange.contains($0.beach.latitude) && longitudeRange.contains($0.beach.longitude) }
            .sorted { lhs, rhs in
                (lhs.id == selectedID ? 1 : 0, lhs.recordCount) > (rhs.id == selectedID ? 1 : 0, rhs.recordCount)
            }
            .map { marker in
                (marker, CGPoint(
                    x: marker.beach.longitude * pointsPerLongitude,
                    y: -marker.beach.latitude * pointsPerLatitude
                ))
            }

        var pinPoints: [CGPoint] = []
        var dots: [(UUID, CGPoint)] = []

        for (marker, point) in ordered {
            let overlaps = pinPoints.contains {
                abs($0.x - point.x) < Self.pinSize.width && abs($0.y - point.y) < Self.pinSize.height
            }

            if !overlaps || marker.id == selectedID {
                pinPoints.append(point)
                pinIDs.insert(marker.id)
            } else {
                dots.append((marker.id, point))
            }
        }

        // 점의 탭 영역이 핀이나 이름표에 조금이라도 닿으면 점을 그리지 않아요. 보이는 핀의 탭을 점이 가로채지 않게 해요.
        let margin = Self.dotSize / 2
        dotIDs = Set(dots.filter { _, point in
            !pinPoints.contains { pin in
                let touchesPin = abs(pin.x - point.x) < Self.pinSize.width / 2 + margin
                    && point.y > pin.y - Self.pinSize.height - margin
                    && point.y < pin.y + margin
                let touchesLabel = abs(pin.x - point.x) < Self.labelSize.width / 2 + margin
                    && point.y > pin.y
                    && point.y < pin.y + Self.labelSize.height + margin
                return touchesPin || touchesLabel
            }
        }.map(\.0))
    }
}

// MARK: - BeachMarkerView

private enum MarkerStyle: Equatable {
    case pin
    case dot
    case hidden
}

/// 해변 하나의 마커. 핀이나 점을 그 크기 그대로 그려요. 탭 영역이 그려진 모양과 같아져요.
private struct BeachMarkerView: View {

    let recordCount: Int
    let style: MarkerStyle
    let isSelected: Bool

    var body: some View {
        switch style {
        case .pin:
            BeachPinView(recordCount: recordCount, isSelected: isSelected)
        case .dot:
            BeachDotView()
        case .hidden:
            EmptyView()
        }
    }
}

// MARK: - BeachPinView

/// 꼬리가 달린 해변 핀. 기록이 없으면 물결, 있으면 쓰레기 봉투와 기록 수 배지를 보여줘요.
/// 선택하면 초록 배경에 흰 아이콘으로 바뀌어요.
private struct BeachPinView: View {

    let recordCount: Int
    let isSelected: Bool

    /// 원(52) + 꼬리(9) - 겹치는 부분(3)
    static let height: CGFloat = 58

    private var background: Color { isSelected ? Color(.green500) : Color(.gray0) }
    private var iconColor: Color { isSelected ? Color(.gray0) : Color(.green500) }

    var body: some View {
        VStack(spacing: -3) {
            icon
                .frame(width: 52, height: 52)
                .background(background, in: Circle())

            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundStyle(background)
                .rotationEffect(.degrees(180))
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        .overlay(alignment: .topTrailing) {
            if recordCount > 0 {
                Text("\(recordCount)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.gray0))
                    .padding(.horizontal, 7)
                    .frame(minWidth: 26, minHeight: 24)
                    .background(Color(.gray900), in: Capsule())
                    .offset(x: 12, y: -6)
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var icon: some View {
        if recordCount > 0 {
            Image(.mapMarkerBag)
                .renderingMode(isSelected ? .template : .original)
                .resizable()
                .scaledToFit()
                .foregroundStyle(iconColor)
                .frame(width: 26, height: 28)
        } else {
            Image(systemName: "water.waves")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - BeachDotView

/// 핀이 겹치는 곳에 대신 찍는 점
private struct BeachDotView: View {

    var body: some View {
        Circle()
            .fill(Color(.gray0))
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(Color(.green500), lineWidth: 2.5)
            }
            .frame(width: MarkerLayout.dotSize, height: MarkerLayout.dotSize)
            .contentShape(Rectangle())
    }
}

// MARK: - Coordinate

private extension Coordinate {

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
