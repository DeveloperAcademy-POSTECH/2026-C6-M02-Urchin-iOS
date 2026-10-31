//
//  OnboardingPage.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

enum OnboardingPage: CaseIterable {
    
    case trashAmount, record, photo, together

    var next: OnboardingPage {
        switch self {
        case .trashAmount: .record
        case .record: .photo
        case .photo: .together
        case .together: .trashAmount
        }
    }
}

extension OnboardingPage {
    
    var title: String {
        switch self {
        case .trashAmount: "14만 4,615톤"
        case .record: "바다를 위해\n한 일을 기록해요"
        case .photo: "달라지는 바다를\n사진으로 남겨요"
        case .together: "작은 실천이 모여\n우리 바다를 지켜요"
        }
    }

    var description: String {
        switch self {
        case .trashAmount: "2025년, 우리나라 해변과 바닷속에서\n수거한 해양쓰레기의 양이에요"
        case .record: "해변에서도, 바닷속에서도\n내가 주운 쓰레기의 종류와 양을 기록해요"
        case .photo: "지구온난화로 변화하는 바다를 함께 살펴요\n발견한 바다생물이나 바다사막화 의심 현장을 촬영해요"
        case .together: "쓰레기를 줍고, 바다의 모습을 기록하며\n우리 바다를 지키는 일에 함께해요"
        }
    }

    // FIXME: - 배경 이미지 결정되면 변경
//    var image: ImageResource {
//        switch self {
//        case .trashAmount:
//            .onboardingTrashAmount
//            
//        case .record:
//            .onboardingRecord
//            
//        case .photo:
//            .onboardingPhoto
//            
//        case .together:
//            .onboardingTogether
//        }
//    }
}
