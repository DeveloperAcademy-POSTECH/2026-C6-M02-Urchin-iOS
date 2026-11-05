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
        .background(Color.white)
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
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.formPrimaryText)
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Spacer()
        }
        .overlay {
            Text("활동 위치 선택")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }
}

// MARK: - 검색 화면

private extension LocationPickerView {

    var searchScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(.horizontal, 20)
                .padding(.top, 24)

            switch store.searchStatus {
            case .idle:
                searchGuide
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

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
                    .padding(.bottom, 90)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
    }

    var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.formPrimaryText)
                .frame(width: 21, height: 21)

            TextField(
                "",
                text: $store.query,
                prompt: Text("어디에서 활동했나요?")
                    .foregroundStyle(Color.formPlaceholderText)
            )
            .focused($isSearchFocused)
            .font(.system(size: 16))
            .foregroundStyle(Color.formPrimaryText)
            .submitLabel(.search)
        }
        .padding(.horizontal, 13)
        .frame(height: 51)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.locationBorder, lineWidth: 1)
        }
    }

    var searchGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이렇게 검색해보세요")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)

            guideItem(title: "해변, 해수욕장 이름", example: "예: 함덕해수욕장, 협재해수욕장")
            guideItem(title: "지역 + 장소 이름", example: "예: 제주 함덕해변, 부산 송정해변")
            guideItem(title: "주변 항구나 명소", example: "예: 함덕항, 서우봉")
        }
    }

    func guideItem(title: String, example: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .foregroundStyle(Color.formPrimaryText)

            Text(example)
                .foregroundStyle(Color.formSecondaryText)
        }
        .font(.system(size: 16))
    }

    func searchResultList(_ results: [PlaceSearchResult]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    Button {
                        store.send(.searchResultTapped(result.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.formPrimaryText)

                            Text(result.address)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.formSecondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.formBorder)
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    var emptyResult: some View {
        VStack(spacing: 4) {
            Text("검색 결과가 없어요")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.formPrimaryText)

            Text("해변이나 해수욕장 이름으로 다시 검색해주세요")
                .font(.system(size: 13))
                .foregroundStyle(Color.formSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    var nearbyBeachesButton: some View {
        Button {
            store.send(.nearbyBeachesTapped)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "map")
                    .font(.system(size: 18))

                Text("주변 해변 보기")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.formPrimaryText)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.white, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
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
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
    }

    /// 핀 끝이 지도 가운데를 가리키도록 핀 높이만큼 위로 올려요.
    var centerPin: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.17), radius: 8, y: 3)

            Image(systemName: "mappin")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.formAccent)
        }
        .offset(y: -20)
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
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.formPrimaryText)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.white, in: Circle())
            .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 위치로 이동")
    }

    var beachPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("활동한 해변을 선택해주세요")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.formPrimaryText)

                    Text("지도를 움직여 활동한 위치를 맞춰주세요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.formSecondaryText)
                }

                beachCard
            }

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .background(Color.white)
    }

    @ViewBuilder
    var beachCard: some View {
        if let beach = store.foundBeach {
            let isSelected = store.isBeachSelected

            Button {
                store.send(.beachCardTapped)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(beach.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.formPrimaryText)

                        Text(beach.address)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.formSecondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    radio(isSelected: isSelected)
                }
                .padding(.horizontal, 15)
                .frame(height: 76)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.formAccent : Color.locationBorder, lineWidth: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            VStack(spacing: 4) {
                Text("근처에 해변이 없어요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.formPrimaryText)

                Text("핀을 해변 가까이로 옮겨주세요")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.formSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(Color.formFieldBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    func radio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.formAccent : Color.formPrimaryText, lineWidth: 1.5)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(Color.formAccent)
                    .frame(width: 10, height: 10)
            }
        }
    }

    var saveButton: some View {
        Button {
            store.send(.saveTapped)
        } label: {
            Text("완료")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(store.isSaveEnabled ? Color.white : Color.formDisabledText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    store.isSaveEnabled ? Color.formAccent : Color.formFieldBackground,
                    in: RoundedRectangle(cornerRadius: 8)
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

// MARK: - Style

private extension Color {

    static let locationBorder = Color(red: 0xE2 / 255, green: 0xE5 / 255, blue: 0xE8 / 255)
}
