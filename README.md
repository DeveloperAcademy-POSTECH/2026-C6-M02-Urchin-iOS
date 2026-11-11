<img width="100%" alt="Plobby banner" src="https://github.com/user-attachments/assets/c6398688-ebe7-4fdf-9055-6fd2d1da80fa" />

# <img src="https://github.com/user-attachments/assets/6a31c332-6a20-49b6-8ad4-6fddb6e24444" width="40" align="absmiddle">  플로비
> 플로깅·플로빙 활동을 기록하고, 봉사 참여 동기를 위한 리워드와 전국 해변 봉사 지도로 함께 바다를 지키고 있음을 체감하게 하는 앱

## 📷 Screenshot
📌 Todo: 추가하기 ~.~

## 🔨 Tech Stack
| Category | Tools & Technologies |
| :--- | :--- |
| **IDE** | Xcode 26.4 |
| **Minimum Deployment Target** | iOS 26.2 |
| **Language** | Swift 6 |
| **UI Framework** | SwiftUI |
| **Architecture** | TCA (The Composable Architecture) |
| **Backend** | Supabase |
| **Push Notification** | FCM (Firebase Cloud Messaging) |
| **Map / Location** | MapKit, Core Location |
| **Animation** | SpriteKit, Core Motion |
| **Concurrency** | Swift Concurrency |
| **Test** | Swift Testing |
| **Package Manager** | SPM (Swift Package Manager) |

## 🛠️ Architecture
```
📌 Todo: 추가하기 ~.~
```

## 📂 Foldering
```
📁 Plobby
├── 📁 App
│   ├── 📝 PlobbyApp
│   ├── 📝 AppDelegate
│   ├── 📝 AppFeature
│   └── 📝 ContentView
├── 📁 Features
│   ├── 📁 Common
│   ├── 📁 MainTab
│   ├── 📁 Onboarding
│   ├── 📁 Login
│   ├── 📁 SignUp
│   ├── 📁 Home
│   │   ├── 📁 GoalList
│   │   ├── 📁 Subviews
│   │   ├── 📝 HomeFeature
│   │   └── 📝 HomeView
│   ├── 📁 Record
│   │   ├── 📁 RecordForm
│   │   ├── 📁 RecordCollecting
│   │   ├── 📁 RecordReward
│   │   ├── 📁 RecordDetail
│   │   ├── 📝 RecordFlowFeature
│   │   └── 📝 RecordView
│   ├── 📁 Map
│   ├── 📁 Collection
│   ├── 📁 My
│   └── 📁 Notification
├── 📁 Domain
│   ├── 📁 Common
│   ├── 📁 Auth
│   ├── 📁 Beach
│   ├── 📁 Goal
│   ├── 📁 Member
│   ├── 📁 Notification
│   └── 📁 Record
├── 📁 Clients
│   ├── 📁 Supabase
│   ├── 📁 Auth
│   ├── 📁 Beach
│   ├── 📁 Goal
│   ├── 📁 Record
│   │   ├── 📁 DTO
│   │   │   ├── 📁 Request
│   │   │   └── 📁 Response
│   │   ├── 📝 RecordClient
│   │   └── 📝 DependencyValues+Record
│   ├── 📁 User
│   ├── 📁 Notification
│   ├── 📁 Push
│   ├── 📁 Location
│   └── 📁 Photo
├── 📁 Core
│   ├── 📁 DesignSystem
│   ├── 📁 Extension
│   ├── 📁 Enum
│   ├── 📁 Common
│   ├── ⚙️ Config.xcconfig
│   └── ⚙️ GoogleService-Info.plist
├── 📁 Resources
│   ├── 🖼️ Assets
│   ├── 🔤 Fonts
│   └── 🗂️ beaches.json
├── 📁 PlobbyTests
└── 📁 PlobbyUITests
```

| 폴더 | 역할 |
| :--- | :--- |
| `App` | 앱 진입점, 루트 흐름(온보딩 · 로그인 · 메인 탭 전환), 푸시 등록 |
| `Features` | 화면 단위 기능. Feature(Reducer)와 View를 1:1로 관리 |
| `Domain` | 앱에서 쓰는 Entity와 입력 규칙. 순수 Swift만 사용 |
| `Clients` | 외부 통신 Dependency Client와 DTO(Request / Response) |
| `Core` | 디자인 시스템, Extension, 공용 Enum, 로거 |
| `Resources` | 이미지 · 색 · 폰트 · 해변 데이터 |

- `import Supabase`는 `Clients/` 안에서만 사용합니다.
- DTO는 `Clients/` 밖으로 내보내지 않고, Feature에서는 `Domain/`의 Entity만 사용합니다.
- `Domain/`은 SwiftUI, TCA, Supabase를 import하지 않습니다.
- `Core/`는 특정 Feature를 참조하지 않습니다.
- `Features/Common`은 화면이 있는 공용 기능, `Core/`는 화면 로직이 없는 공용 코드입니다.

> `Core/Config.xcconfig`, `Core/GoogleService-Info.plist`는 저장소에 포함되지 않습니다. 팀 채널에서 받아 같은 위치에 넣어 주세요.

## 📌 Convention
### Code Style
[Swift 스타일쉐어 가이드](https://github.com/StyleShare/swift-style-guide)를 기반으로 하되, 팀원의 기존 스타일과 SwiftUI 프로젝트 특성을 반영하여 일부 규칙은 재정의했습니다.
[코딩 컨벤션](https://furtive-purchase-33f.notion.site/3e4fe29d786d80edbdc0fc5d656d785c) 문서를 참고해주세요!

### Commit
| 타입 | 설명 |
| :---: | --- |
| `add` | 파일, 에셋 추가 |
| `chore` | 자잘한 코드 수정 |
| `docs` | 문서 작성 및 수정 (README.md 등) |
| `feat` | 기능 구현 |
| `fix` | 버그 수정 |
| `refactor` | 코드 리팩토링 |
| `style` | UI 작업 |
| `setting` | 프로젝트 세팅 |

```
[타입/#이슈번호] 설명
ex) [style/#12] 로그인 버튼 UI 컴포넌트 구현
```

- 타입은 반드시 소문자로 작성합니다.
- 설명은 한글로, 50자 이내의 명사형으로 간결하게 작성합니다. (Ex. ~ 구현, ~ 추가)
- 너무 많은 내용을 한 번에 커밋하지 않고, 잘 쪼개서 커밋해주세요.

### Branch
| 브랜치 | 설명 |
| :---: | --- |
| `main` | 배포 브랜치 |
| `develop` | 개발 통합 브랜치 (디폴트) |
| `타입/#이슈번호-작업명` | 작업 브랜치 |

```
타입/#이슈번호-작업명
ex) feat/#3-login
```

- 타입은 [Commit](#commit) 컨벤션과 동일합니다.
- 작업명은 영어 소문자로 작성하고, 단어는 `-`로 연결합니다. (Ex. `style/#12-login-button`)
- 디폴트 브랜치는 `develop`으로 설정합니다.
- `main`에는 직접 커밋하지 않으며, 배포 시점에 `develop` → `main` PR로만 반영합니다.

## 🌊 Git Flow
1. 작업할 내용에 대한 이슈를 생성합니다.
2. 이슈 번호를 확인하고, 브랜치 컨벤션에 맞게 **GitHub에서** 브랜치를 생성합니다.
   - 반드시 최신 `develop` 브랜치에서 파생해야 합니다.
   - 로컬에서는 `git fetch origin` → `git switch 브랜치이름`으로 이동합니다.
3. 작업 내용을 적당히 쪼개어 로컬에서 `commit` 합니다.
4. 작업이 완료되면 `push` 후 PR을 자세히 작성합니다.
   - `push` 전 최신 `develop`을 작업 브랜치에 `merge` 하고, 빌드되는지 꼭 확인합니다.
5. 코드 리뷰 후 모든 개발 팀원의 `approve`를 받으면 `develop`에 `merge` 합니다.
   - `merge` 후 원격 브랜치는 삭제합니다. (로컬 브랜치는 남겨두는 것을 권장합니다.)
6. `merge` 후 팀원에게 알리고, 모든 팀원은 로컬 `develop`을 최신화합니다.

## 🧑‍💻 Team Members
| | | | | |
| :--: | :--: | :--: | :--: | :--: |
| [김예빈](https://github.com/ErinKYB) | [이선우](https://github.com/dlsundn) | [이은지](https://github.com/oeunji) | [정지나](https://github.com/J1naChung) | [허승준](https://github.com/dev-domo) |
| 에린(Erin) | 신디(Cindy) | 로시(Rossi) | 지나(Jina) | 더스틴(Dustin) |
| Designer | iOS · Backend | iOS | Designer | iOS · Backend |
