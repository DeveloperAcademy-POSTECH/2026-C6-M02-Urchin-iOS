//
//  LocationPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import MapKit
import SwiftUI

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct LocationPickerView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<LocationPickerFeature>

    @State private var cameraPosition: MapCameraPosition = .automatic
    @FocusState private var isSearchFocused: Bool

    private static let mapSpanMeters: CLLocationDistance = 1_500

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            switch store.screen {
            case .search:
                searchScreen
            case .map:
                mapScreen
            }
        }
        .background(Color(.gray0))
        .onAppear {
            cameraPosition = Self.cameraPosition(for: store.cameraTarget.center)
        }
        .onChange(of: store.cameraTarget) { _, target in
            withAnimation {
                cameraPosition = Self.cameraPosition(for: target.center)
            }
        }
    }
}

// MARK: - Navigation Bar

private extension LocationPickerView {

    var navigationBar: some View {
        HStack(spacing: 0) {
            Button {
                store.send(.backTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17.scaled, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 44.scaled, height: 44.scaled, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Spacer()
        }
        .overlay {
            Text("활동 위치 선택")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
        }
        .padding(.horizontal, 20.scaled)
        .frame(height: 56.scaled)
    }
}

// MARK: - 검색 화면

private extension LocationPickerView {

    var searchScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(.horizontal, 20.scaled)
                .padding(.top, 24.scaled)

            switch store.searchStatus {
            case .idle:
                searchGuide
                    .padding(.horizontal, 20.scaled)
                    .padding(.top, 24.scaled)

            case let .results(results):
                searchResultList(results)

            case .empty:
                emptyResult
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            if !isSearchFocused {
                nearbyBeachesButton
                    .padding(.bottom, 90.scaled)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
    }

    var searchField: some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16.scaled, weight: .medium))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 21.scaled, height: 21.scaled)

            TextField(
                "",
                text: $store.query,
                prompt: Text("어디에서 활동했나요?")
                    .foregroundStyle(Color(.textTertiary))
            )
            .focused($isSearchFocused)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
            .submitLabel(.search)
        }
        .padding(.horizontal, 13.scaled)
        .frame(height: 51.scaled)
        .overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .stroke(Color(.gray300), lineWidth: 1)
        }
    }

    var searchGuide: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            Text("이렇게 검색해보세요")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            guideItem(title: "해변, 해수욕장 이름", example: "예: 함덕해수욕장, 협재해수욕장")
            guideItem(title: "지역 + 장소 이름", example: "예: 제주 함덕해변, 부산 송정해변")
            guideItem(title: "주변 항구나 명소", example: "예: 함덕항, 서우봉")
        }
    }

    func guideItem(title: String, example: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .foregroundStyle(Color(.textPrimary))

            Text(example)
                .foregroundStyle(Color(.textSecondary))
        }
        .plobbyFont(.body)
    }

    func searchResultList(_ results: [PlaceSearchResult]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    Button {
                        store.send(.searchResultTapped(result.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 4.scaled) {
                            Text(result.name)
                                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                                .foregroundStyle(Color(.textPrimary))

                            Text(result.address)
                                .plobbyFont(.helper)
                                .foregroundStyle(Color(.textSecondary))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14.scaled)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(.currentWarmBorder))
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 20.scaled)
            .padding(.top, 12.scaled)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    var emptyResult: some View {
        VStack(spacing: 4.scaled) {
            Text("검색 결과가 없어요")
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                .foregroundStyle(Color(.textPrimary))

            Text("해변이나 해수욕장 이름으로 다시 검색해주세요")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80.scaled)
    }

    var nearbyBeachesButton: some View {
        Button {
            store.send(.nearbyBeachesTapped)
        } label: {
            HStack(spacing: 10.scaled) {
                Image(systemName: "map")
                    .font(.system(size: 18.scaled))

                Text("주변 해변 보기")
                    .plobbyFont(.actionLabel)
            }
            .foregroundStyle(Color(.textPrimary))
            .padding(.horizontal, 16.scaled)
            .frame(height: 44.scaled)
            .background(Color(.gray0), in: Capsule())
            .shadow(color: Color(.neutralBlack).opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 지도 화면

private extension LocationPickerView {

    var mapScreen: some View {
        VStack(spacing: 0) {
            map
            beachPanel
        }
    }

    var map: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom])
            .onMapCameraChange(frequency: .onEnd) { context in
                store.send(.mapCameraChangeEnded(center: Coordinate(
                    latitude: context.region.center.latitude,
                    longitude: context.region.center.longitude
                )))
            }
            .overlay {
                centerPin
            }
            .overlay(alignment: .bottomTrailing) {
                currentLocationButton
                    .padding(.trailing, 20.scaled)
                    .padding(.bottom, 20.scaled)
            }
    }

    /// 핀 끝이 지도 가운데를 가리키도록 핀 높이의 절반만큼 위로 올려요.
    var centerPin: some View {
        Image(.searchResultPin)
            .resizable()
            .scaledToFit()
            .frame(width: 36.scaled, height: 42.scaled)
            .offset(y: -21.scaled)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    var currentLocationButton: some View {
        Button {
            store.send(.currentLocationButtonTapped)
        } label: {
            ZStack {
                if store.isLocating {
                    ProgressView()
                } else {
                    Image(systemName: "location")
                        .font(.system(size: 18.scaled, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                }
            }
            .frame(width: 44.scaled, height: 44.scaled)
            .background(Color(.gray0), in: Circle())
            .shadow(color: Color(.neutralBlack).opacity(0.10), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 위치로 이동")
    }

    var beachPanel: some View {
        VStack(alignment: .leading, spacing: 24.scaled) {
            VStack(alignment: .leading, spacing: 16.scaled) {
                VStack(alignment: .leading, spacing: 8.scaled) {
                    Text("활동한 해변을 선택해주세요")
                        .plobbyFont(.heading)
                        .foregroundStyle(Color(.textPrimary))

                    Text("지도를 움직여 활동한 위치를 맞춰주세요")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                }

                beachCard
            }

            saveButton
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 24.scaled)
        .padding(.bottom, 8.scaled)
        .background(Color(.gray0))
    }

    @ViewBuilder
    var beachCard: some View {
        if let beach = store.foundBeach {
            let isSelected = store.isBeachSelected

            Button {
                store.send(.beachCardTapped)
            } label: {
                HStack(spacing: 12.scaled) {
                    VStack(alignment: .leading, spacing: 4.scaled) {
                        Text(beach.name)
                            .plobbyFont(.cardTitle)
                            .foregroundStyle(Color(.textPrimary))

                        Text(beach.address)
                            .plobbyFont(.helper)
                            .foregroundStyle(Color(.textSecondary))
                            .lineLimit(1)
                    }

                    Spacer()

                    radio(isSelected: isSelected)
                }
                .padding(.horizontal, 15.scaled)
                .frame(height: 76.scaled)
                .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12.scaled))
                .overlay {
                    RoundedRectangle(cornerRadius: 12.scaled)
                        .stroke(isSelected ? Color(.green500) : Color(.gray300), lineWidth: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            VStack(spacing: 4.scaled) {
                Text("근처에 해변이 없어요")
                    .plobbyFont(.notification)
                    .foregroundStyle(Color(.textPrimary))

                Text("핀을 해변 가까이로 옮겨주세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76.scaled)
            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
        }
    }

    func radio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color(.green500) : Color(.textPrimary), lineWidth: 1.5)
                .frame(width: 22.scaled, height: 22.scaled)

            if isSelected {
                Circle()
                    .fill(Color(.green500))
                    .frame(width: 10.scaled, height: 10.scaled)
            }
        }
    }

    var saveButton: some View {
        Button {
            store.send(.saveTapped)
        } label: {
            Text("완료")
                .plobbyFont(.actionLabel)
                .foregroundStyle(store.isSaveEnabled ? Color(.gray0) : Color(.textDisabled))
                .frame(maxWidth: .infinity)
                .frame(height: 54.scaled)
                .background(
                    store.isSaveEnabled ? Color(.green500) : Color(.gray50),
                    in: RoundedRectangle(cornerRadius: 8.scaled)
                )
        }
        .buttonStyle(.plain)
        .disabled(!store.isSaveEnabled)
    }
}

// MARK: - Functions

private extension LocationPickerView {

    static func cameraPosition(for center: Coordinate) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            latitudinalMeters: mapSpanMeters,
            longitudinalMeters: mapSpanMeters
        ))
    }
}
