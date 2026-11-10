//
//  UserHomeView.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import SwiftUI

import ComposableArchitecture

struct UserHomeView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<UserHomeFeature>

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(title: "프로필") {
                store.send(.backTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 40.scaled) {
                    profile

                    RecordListSection(
                        records: store.filteredRecords,
                        selectedFilter: store.recordFilter,
                        onFilterChanged: { store.send(.recordFilterChanged($0)) },
                        onRecordTapped: { store.send(.recordTapped($0)) }
                    )
                }
                .padding(.horizontal, 20.scaled)
                .padding(.bottom, 24.scaled)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.send(.task).finish()
        }
        .navigationDestination(item: $store.scope(state: \.recordDetail, action: \.recordDetail)) { store in
            RecordDetailView(store: store)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - 프로필

extension UserHomeView {

    private var profile: some View {
        HStack(alignment: .center, spacing: 16.scaled) {
            AsyncImage(url: store.profileImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(Color(.gray600))
            }
            .frame(width: 48.scaled, height: 48.scaled)
            .clipShape(Circle())

            Text(store.nickname)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 16.scaled)
    }
}
