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

    private static let sheetHeight: CGFloat = 357.scaled

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            mapContent
                .overlay(alignment: .bottom) {
                    beachSheet
                }
                .animation(.smooth(duration: 0.3), value: store.beachSheet != nil)
                // 해변 시트가 탭 바 자리까지 덮어요.
                .toolbar(store.beachSheet == nil ? .visible : .hidden, for: .tabBar)
                .toolbar(.hidden, for: .navigationBar)
        } destination: { store in
            destination(store)
                .toolbar(.hidden, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
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

    /// 해변 시트를 띄워도 지도를 계속 움직이고 다른 마커를 누를 수 있게 지도 위에 얹어요.
    @ViewBuilder
    private var beachSheet: some View {
        if let sheetStore = store.scope(state: \.beachSheet, action: \.beachSheet.presented) {
            PlobbyBottomSheetPanel(cornerRadius: 24.scaled) {
                BeachSheetView(store: sheetStore)
                    .frame(height: Self.sheetHeight)
            }
            .transition(.move(edge: .bottom))
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
            // 화면 근처에서 보이는 핀과 클러스터만 지도에 올려요.
            // MapKit은 주석 뷰의 크기로 탭을 판정해서, 뷰 크기를 그려지는 모양에 딱 맞춰요.
            ForEach(markers.filter { layout.pinIDs.contains($0.id) }) { marker in
                Annotation(marker.beach.name, coordinate: marker.beach.coordinate.location, anchor: .bottom) {
                    BeachPinView(
                        recordCount: marker.recordCount,
                        isSelected: marker.id == store.selectedBeachID
                    )
                }
                .tag(marker.id)
            }

            // 겹친 해변은 기록 수를 더한 숫자 원 하나로 묶어요. 이름은 보여주지 않아요.
            ForEach(layout.clusters) { cluster in
                Annotation("", coordinate: cluster.coordinate.location, anchor: .center) {
                    BeachClusterView(recordCount: cluster.recordCount)
                }
                .annotationTitles(.hidden)
                .tag(cluster.id)
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

            if store.isShowingCurrentLocation, !Self.isLooking(at: store.currentLocation, in: context.region) {
                store.send(.cameraMovedAwayFromCurrentLocation)
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            mapSize = size
        }
        .onChange(of: tappedMarkerID) { _, id in
            guard let id else { return }
            tappedMarkerID = nil

            if let cluster = layout.cluster(for: id) {
                store.send(.clusterTapped(cluster.markers))
            } else if layout.pinIDs.contains(id), let marker = markers.first(where: { $0.id == id }) {
                store.send(.markerTapped(marker))
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 14.scaled) {
                searchBar
                    .padding(.horizontal, 20.scaled)

                if store.isMember, !store.favoriteBeaches.isEmpty {
                    favoriteChips
                }

                if store.authorization == .denied {
                    locationOffBadge
                }
            }
            .padding(.top, 8.scaled)
        }
        .overlay(alignment: .bottomTrailing) {
            currentLocationButton
                .padding(.trailing, 20.scaled)
                .padding(.bottom, 16.scaled)
        }
    }

    var searchBar: some View {
        Button {
            store.send(.searchButtonTapped)
        } label: {
            SearchBar {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17.scaled, weight: .medium))
                    .foregroundStyle(Color(.textSecondary))
            } content: {
                Text(SearchBarText.placeholder)
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.gray600))
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    /// 관심 해변 칩. 시트가 열린 해변의 칩만 선택된 모양이에요.
    var favoriteChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8.scaled) {
                ForEach(store.favoriteBeaches) { beach in
                    Button {
                        store.send(.favoriteChipTapped(beach))
                    } label: {
                        BeachChip(
                            title: beach.name,
                            style: beach.id == store.selectedBeachID ? .selectedSearchFavorite : .searchFavorite
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            // 칩 테두리가 잘리지 않게 위아래로 여유를 둬요.
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
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
            .padding(.horizontal, 16.scaled)
            .padding(.vertical, 4.scaled)
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
                        .foregroundStyle(store.isShowingCurrentLocation ? Color(.green500) : Color(.textPrimary))
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

    /// 현위치가 화면 가운데 근처(보이는 범위의 10% 안)에 있으면 현위치를 보고 있다고 봐요.
    static func isLooking(at location: Coordinate?, in region: MKCoordinateRegion) -> Bool {
        guard let location else { return false }
        return abs(region.center.latitude - location.latitude) < region.span.latitudeDelta * 0.1
            && abs(region.center.longitude - location.longitude) < region.span.longitudeDelta * 0.1
    }

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

/// 화면에서 서로 겹치는 해변을 하나의 클러스터로 묶어요. 선택한 해변, 기록이 많은 해변 순서로 자리를 먼저 차지하고,
/// 그 자리에 겹치는 해변들이 뒤따라 묶여요. 혼자 남은 해변은 핀, 둘 이상 묶이면 숫자 원으로 보여줘요.
private struct MarkerLayout {

    /// 핀(배지 포함)이 차지하는 크기. 핀은 좌표 위쪽으로 그려져요.
    static let pinSize = CGSize(width: 68.scaled, height: 76.scaled)
    /// 클러스터 원의 지름
    static let clusterSize: CGFloat = 52.scaled

    /// 여러 해변을 묶은 클러스터예요. 가장 먼저 자리를 차지한 해변 위치에 그려요.
    struct Cluster: Identifiable {
        /// 맨 앞 해변의 ID를 그대로 써요. MapKit 선택 태그로도 써요.
        let id: UUID
        let coordinate: Coordinate
        let markers: [BeachMarker]

        var recordCount: Int {
            markers.reduce(0) { $0 + $1.recordCount }
        }
    }

    private(set) var pinIDs: Set<UUID> = []
    private(set) var clusters: [Cluster] = []

    static func isSameRegion(_ lhs: MKCoordinateRegion?, _ rhs: MKCoordinateRegion) -> Bool {
        guard let lhs else { return false }
        let tolerance = 1e-9
        return abs(lhs.center.latitude - rhs.center.latitude) < tolerance
            && abs(lhs.center.longitude - rhs.center.longitude) < tolerance
            && abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta) < tolerance
            && abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta) < tolerance
    }

    func cluster(for id: UUID) -> Cluster? {
        clusters.first { $0.id == id }
    }

    init(markers: [BeachMarker], selectedID: UUID?, region: MKCoordinateRegion, mapSize: CGSize) {
        // 지도 크기를 알기 전에는 아무것도 그리지 않아요.
        guard mapSize.width > 0, mapSize.height > 0 else { return }

        let pointsPerLongitude = mapSize.width / region.span.longitudeDelta
        let pointsPerLatitude = mapSize.height / region.span.latitudeDelta

        // 화면 밖 해변은 계산에서 빼요. 움직일 때 미리 그려 두도록 화면 크기만큼 여유를 둬요.
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

        // 자리를 차지한 해변(그룹의 기준점)과 그 자리에 묶인 해변들
        var groups: [(anchor: CGPoint, markers: [BeachMarker], isSelected: Bool)] = []

        for (marker, point) in ordered {
            // 선택한 해변은 늘 핀으로 따로 보여줘요.
            if marker.id == selectedID {
                groups.append((point, [marker], true))
                continue
            }

            let index = groups.firstIndex { group in
                !group.isSelected
                    && abs(group.anchor.x - point.x) < Self.pinSize.width
                    && abs(group.anchor.y - point.y) < Self.pinSize.height
            }

            if let index {
                groups[index].markers.append(marker)
            } else {
                groups.append((point, [marker], false))
            }
        }

        for group in groups {
            guard let first = group.markers.first else { continue }

            if group.markers.count == 1 {
                pinIDs.insert(first.id)
            } else {
                clusters.append(Cluster(id: first.id, coordinate: first.beach.coordinate, markers: group.markers))
            }
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
    static let height: CGFloat = 58.scaled

    private var background: Color { isSelected ? Color(.green500) : Color(.gray0) }
    private var iconColor: Color { isSelected ? Color(.gray0) : Color(.green500) }

    var body: some View {
        VStack(spacing: -3) {
            icon
                .frame(width: 52.scaled, height: 52.scaled)
                .background(background, in: Circle())

            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundStyle(background)
                .rotationEffect(.degrees(180))
        }
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
                .frame(width: 26.scaled, height: 28.scaled)
        } else {
            Image(systemName: "water.waves")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - BeachClusterView

/// 겹친 해변들을 묶은 원. 묶인 해변의 기록 수 합을 보여주고, 기록이 없으면 물결을 보여줘요.
private struct BeachClusterView: View {

    let recordCount: Int

    var body: some View {
        Group {
            if recordCount > 0 {
                Text("\(recordCount)")
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 18))
                    .foregroundStyle(Color(.currentBrandText))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            } else {
                Image(systemName: "water.waves")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(.green500))
            }
        }
        .frame(width: MarkerLayout.clusterSize, height: MarkerLayout.clusterSize)
        .background(Color(.gray0), in: Circle())
        .contentShape(Circle())
        .accessibilityLabel(recordCount > 0 ? "해변 묶음, 기록 \(recordCount)개" : "해변 묶음")
    }
}

// MARK: - Coordinate

private extension Coordinate {

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
