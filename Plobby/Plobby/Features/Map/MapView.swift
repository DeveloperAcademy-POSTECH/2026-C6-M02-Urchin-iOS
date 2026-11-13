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
        mapContent
            .sheet(item: $store.scope(state: \.beachSheet, action: \.beachSheet)) { store in
                BeachSheetView(store: store)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .presentationDetents([.height(Self.sheetHeight)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.sheetHeight)))
                    .presentationCornerRadius(24.scaled)
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
    static func destination(_ store: StoreOf<MapFeature.Path>) -> some View {
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

        return Map(position: $cameraPosition, selection: $tappedMarkerID) {
            ForEach(markers.filter { layout.pinIDs.contains($0.id) }) { marker in
                Annotation(marker.beach.name, coordinate: marker.beach.coordinate.location, anchor: .bottom) {
                    BeachPinView(
                        recordCount: marker.recordCount,
                        isSelected: marker.id == store.selectedBeachID
                    )
                }
                .tag(marker.id)
            }

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
        .onMapCameraChange(frequency: .onEnd) { context in
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
                Text(SearchBarPlaceholder.beachOrResort)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

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
            .background {
                Circle()
                    .fill(Color(.gray0))
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 위치로 이동")
    }
}

// MARK: - Functions

private extension MapView {

    static func isLooking(at location: Coordinate?, in region: MKCoordinateRegion) -> Bool {
        guard let location else { return false }
        return abs(region.center.latitude - location.latitude) < region.span.latitudeDelta * 0.1
            && abs(region.center.longitude - location.longitude) < region.span.longitudeDelta * 0.1
    }

    static func cameraPosition(for command: CameraCommand) -> MapCameraPosition {
        .region(region(for: command))
    }

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

private struct MarkerLayout {

    static let pinSize = CGSize(width: 68.scaled, height: 76.scaled)
    static let clusterSize: CGFloat = 52.scaled

    struct Cluster: Identifiable {
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
        guard mapSize.width > 0, mapSize.height > 0 else { return }

        let pointsPerLongitude = mapSize.width / region.span.longitudeDelta
        let pointsPerLatitude = mapSize.height / region.span.latitudeDelta

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

        var groups: [(anchor: CGPoint, markers: [BeachMarker], isSelected: Bool)] = []

        for (marker, point) in ordered {
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

private struct BeachPinView: View {

    let recordCount: Int
    let isSelected: Bool

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
