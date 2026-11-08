//
//  TrashCategory+CollectionFact.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

struct CollectionFact: Equatable {
    let title: String
    let description: String
    let source: String
}

extension TrashCategory {

    func collectionFact(count: Int, nickname: String?) -> CollectionFact {
        // TODO: 빈 상태 문구 디자인 확정 후 교체
        guard count > 0 else {
            return CollectionFact(
                title: "아직 모은\n\(name) 쓰레기가 없어요",
                description: "바다에서 \(name) 쓰레기를 주우면 지켜낸 바다 생물 이야기를 볼 수 있어요.",
                source: ""
            )
        }

        let thanks = "\(nickname.map { "\($0)님" } ?? "여러분") 덕분에"
        let perFour = (count + 3) / 4

        switch self {
        case .glass:
            return CollectionFact(
                title: "소라게 \(count * 9)마리를\n지키는 데 힘을 보탰어요!",
                description: "작은 생물이 버려진 유리병에 들어가면 빠져나오기 어려워요. \(thanks) 소라게가 새집을 찾는 길이 조금 더 안전해졌어요.",
                source: "출처: 인도 야생동물연구소"
            )
        case .plastic:
            return CollectionFact(
                title: "바다거북 \(perFour)마리를\n지키는 데 힘을 보탰어요!",
                description: "바다거북은 물에 떠다니는 비닐을 해파리로 착각할 수 있어요. \(thanks) 바다거북이 헤엄치는 바다가 조금 더 안전해졌어요.",
                source: "출처: Ocean Conservancy"
            )
        case .metal:
            return CollectionFact(
                title: "돌고래 \(count)마리를\n지키는 데 힘을 보탰어요!",
                description: "돌고래는 알루미늄 포일이 목에 걸리면 먹이를 삼키기 어려워요. \(thanks) 돌고래가 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                source: "출처: 미국 해양대기청(NOAA)"
            )
        case .wood:
            return CollectionFact(
                title: "고둥을\n지키는 데 힘을 보탰어요!",
                description: "버려진 방부목이 바다에 잠기면 구리 성분이 녹아내려 고둥들이 껍데기 속에 들어간 채 움직이지 못할 수 있어요. \(thanks) 고둥이 사는 갯벌이 조금 더 안전해졌어요.",
                source: "출처: 뉴저지 의과대학 · 남부 캘리포니아 연안 수질 연구 프로젝트(SCCWRP)"
            )
        case .fishingGear:
            return CollectionFact(
                title: "물범 \(perFour)마리를\n지키는 데 힘을 보탰어요!",
                description: "물범은 버려진 그물이나 낚싯줄이 몸에 감기면 숨을 쉬러 물 위로 올라오지 못할 때도 있어요. \(thanks) 물범이 헤엄치는 바다가 조금 더 안전해졌어요.",
                source: "출처: Ocean Conservancy"
            )
        case .clothing:
            return CollectionFact(
                title: "홍합을\n지키는 데 힘을 보탰어요!",
                description: "버려진 폴리에스터 천이 햇빛과 물살에 닳으면 아주 작은 플라스틱 섬유가 떨어져 나와요. 홍합이 먹이를 걸러 먹다가 섬유까지 삼키게 되면 성장이 눈에 띄게 더뎌질 수 있어요. \(thanks) 어린 홍합들이 자라는 바다가 조금 더 안전해졌어요.",
                source: "출처: 중국환경과학연구원 · 플리머스 해양연구소"
            )
        case .styrofoam:
            return CollectionFact(
                title: "바다거북 \(count)마리를\n지키는 데 힘을 보탰어요!",
                description: "바다거북은 배 속에 스티로폼 조각이 쌓이면 몸이 물에 더 잘 떠서, 먹이를 찾으러 깊이 잠수하기 어려울 수 있어요. \(thanks) 바다거북이 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                source: "출처: Ocean Conservancy"
            )
        case .can:
            return CollectionFact(
                title: "흰동가리 \(count)마리를\n지키는 데 힘을 보탰어요!",
                description: "흰동가리처럼 작은 물고기는 바닷바닥에 가라앉은 캔에 들어갔다가 빠져나오지 못할 때가 있어요. \(thanks) 흰동가리가 헤엄치는 바다가 조금 더 안전해졌어요.",
                source: "출처: 파트라스대학교"
            )
        case .paper:
            return CollectionFact(
                title: "플랑크톤 \(count * 3)마리를\n지키는 데 힘을 보탰어요!",
                description: "종이컵이 물에 오래 남으면 안쪽 코팅에서 아주 작은 플라스틱 조각이 떨어져 나올 수 있어요. \(thanks) 플랑크톤이 사는 바다가 조금 더 안전해졌어요.",
                source: "출처: 아마시아대학교 · 위스퀴다르대학교"
            )
        case .rubber:
            return CollectionFact(
                title: "바닷새 \(count)마리를\n지키는 데 힘을 보탰어요!",
                description: "바닷새가 풍선 조각을 삼키면 먹이를 제대로 소화하기 어려워요. \(thanks) 바닷새가 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                source: "출처: Ocean Conservancy"
            )
        case .etc:
            return CollectionFact(
                title: "바닷물 \(count)L를\n깨끗하게 지키는 데 힘을 보탰어요!",
                description: "담배꽁초가 물에 잠기면 니코틴과 납 같은 성분이 녹아 나와요. \(thanks) 바다가 조금 더 안전해졌어요.",
                source: "출처: 부셰르 의과대학교 · 조지아공과대학교 · 샌디에이고주립대학교"
            )
        }
    }
}
