//
//  PhotoSelection.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

struct PhotoSelection: Equatable, Sendable {
    
    static let maxCount = 5
    
    /// 선택 순서대로 저장. 외부에서 직접 수정하지 못하게 막아 한도 규칙을 지킨다.
    private(set) var assets: [PhotoAsset]
    
    /// 이번에 고를 수 있는 장수. 기록 양식에 이미 사진이 있으면 남은 장수만큼만 고를 수 있다.
    let limit: Int
    
    init(_ assets: [PhotoAsset] = [], limit: Int = Self.maxCount) {
        let limit = min(max(limit, 0), Self.maxCount)
        var unique: [PhotoAsset] = []
        for asset in assets where !unique.contains(asset) && unique.count < limit {
            unique.append(asset)
        }
        self.assets = unique
        self.limit = limit
    }
    
    var count: Int {
        assets.count
    }
    var isEmpty: Bool {
        assets.isEmpty
    }
    var isFull: Bool {
        assets.count >= limit
    }
    
    /// 첫 번째 사진이 대표사진
    var representative: PhotoAsset? {
        assets.first
    }
    
    /// 카메라 버튼 아래 "2/5"
    var countText: String { "\(count)/\(Self.maxCount)" }
    
    func contains(_ id: PhotoAsset.ID) -> Bool {
        assets.contains { $0.id == id }
    }
    
    /// 셀 우측 상단 선택 순서 배지 (1부터, 선택 안 됐으면 nil)
    func order(of id: PhotoAsset.ID) -> Int? {
        assets.firstIndex { $0.id == id }.map { $0 + 1 }
    }
    
    enum ToggleResult: Equatable {
        case selected
        case deselected
        /// 이미 5장이라 선택되지 않음 → 화면에서 토스트를 띄운다.
        case limitExceeded
    }
    
    /// 선택돼 있으면 해제, 아니면 맨 뒤에 추가
    @discardableResult
    mutating func toggle(_ asset: PhotoAsset) -> ToggleResult {
        if contains(asset.id) {
            remove(id: asset.id)
            return .deselected
        }
        return append(asset) ? .selected : .limitExceeded
    }
    
    /// 한도 안이면 추가하고 true, 이미 있거나 가득 찼으면 false
    @discardableResult
    mutating func append(_ asset: PhotoAsset) -> Bool {
        guard !isFull, !contains(asset.id) else { return false }
        assets.append(asset)
        return true
    }
    
    /// 해제하면 뒤 사진들의 순서가 하나씩 당겨진다. (대표사진을 지우면 다음 사진이 대표가 됨)
    mutating func remove(id: PhotoAsset.ID) {
        assets.removeAll { $0.id == id }
    }
}
