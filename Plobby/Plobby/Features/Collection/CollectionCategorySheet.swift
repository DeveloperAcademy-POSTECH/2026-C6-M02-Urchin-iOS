//
//  CollectionCategorySheet.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct CollectionCategorySheet: View {

    // MARK: - Properties

    let store: StoreOf<CollectionFeature>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10.scaled), count: 3)

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            categoryGrid

            Spacer()
        }
        .background(Color(.gray0))
    }
}

// MARK: - Header

private extension CollectionCategorySheet {

    var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                title
                subTitle
            }
            
            Spacer()

            closeButton
        }
        .padding(.top, 16.scaled)
        .padding(.vertical, 16.scaled)
    }
    
    var title: some View {
        Text("전체 분류")
            .plobbyFont(.headingLarge)
            .foregroundStyle(Color(.textPrimary))
            .padding(.leading, 20.scaled)
    }
    
    var subTitle: some View {
        Text("이번 시범에서는 플라스틱, 유리, 나무를 선택할 수 있어요.")
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textSecondary))
            .padding(.top, 3.scaled)
            .padding(.leading, 20.scaled)
    }

    var closeButton: some View {
        Button {
            store.send(.categorySheetPresentationChanged(false))
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10.scaled, weight: .medium))
                .frame(width: 20.scaled, height: 20.scaled)
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 36.scaled, height: 36.scaled)
                .background(Color(.gray50), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.currentWarmBorder), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20.scaled)
    }
}

// MARK: - Category Cell

private extension CollectionCategorySheet {
    
    var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 10.scaled) {
            ForEach(TrashCategory.allCases, id: \.self) { category in
                categoryCell(category)
            }
        }
        .padding(.horizontal, 20.scaled)
    }

    func categoryCell(_ category: TrashCategory) -> some View {
        let isSelected = store.card.selectedCategory == category
        let count = store.card.collectedCounts[category, default: 0]

        return Button {
            store.send(.categoryTapped(category))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                thumbnail(category)
                categoryName(category)
                collectedCount(count, isSelected: isSelected)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120.scaled)
            .background(
                isSelected ? Color(.surfaceBrandSubtle) : Color(.gray50),
                in: RoundedRectangle(cornerRadius: 12.scaled)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12.scaled)
                        .strokeBorder(Color(.green500), lineWidth: 1)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18.scaled))
                        .foregroundStyle(Color(.gray0), Color(.currentBrandText))
                        .padding(8.scaled)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func thumbnail(_ category: TrashCategory) -> some View {
        Image(category.thumbnailName)
            .resizable()
            .scaledToFit()
            .frame(width: 50.scaled, height: 50.scaled)
            .frame(maxWidth: .infinity)
            .padding(.top, 16.scaled)
            .padding(.bottom, 8.scaled)
    }

    func categoryName(_ category: TrashCategory) -> some View {
        Text(category.name)
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.textPrimary))
            .lineLimit(1)
            .padding(.horizontal, 8.scaled)
    }

    func collectedCount(_ count: Int, isSelected: Bool) -> some View {
        Text("\(count)개")
            .plobbyFont(.helper)
            .foregroundStyle(isSelected ? Color(.currentBrandText) : Color(.textTertiary))
            .padding(.horizontal, 8.scaled)
            .padding(.bottom, 8.scaled)
    }
}
