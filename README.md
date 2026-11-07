# Plobby
> 해양 정화 봉사자에게는 꾸준한 활동 동기를, 기관에게는 해양 환경 관리 이력을 한눈에 제공하는 서비스

## 📷 Screenshot
📌 Todo: 추가하기 ~.~

## 🔨 Tech Stack
| Category | Tools & Technologies |
| :--- | :--- |
| **IDE** | Xcode 26.x |
| **Minimum Deployment Target** | iOS 26.4 |
| **Language** | Swift 6 |
| **UI Framework** | SwiftUI |
| **Architecture** | TCA (The Composable Architecture) |
| **Backend** | Supabase |
| **Concurrency** | Swift Concurrency |
| **Test** | Swift Testing |
| **Package Manager** | Swift Package Manager (SPM) |

## 🛠️ Architecture
```
📌 Todo: 추가하기 ~.~
```

## 📂 Foldering
```
Plobby
├── Plobby
│   ├── App            # 앱 진입점(PlobbyApp), 루트 화면, 탭 구성, 딥링크·푸시 진입 처리
│   ├── Features       # 화면 단위 기능. 기능별 폴더에 Reducer와 View를 한 쌍으로 관리 (ex. Feed/, Record/)
│   ├── Domain         # 데이터 모델(Entity)과 규칙(제목 생성, 입력 검증 등). 순수 Swift만 사용
│   ├── Clients        # 외부와 통신하는 Dependency Client. Client별 폴더에 인터페이스, live 구현, DTO 관리
│   ├── Core           # 색·글꼴, 여러 기능이 같이 쓰는 공용 UI 컴포넌트와 Extension
│   └── Resources      # Assets(이미지·색), 문자열 등 리소스
├── PlobbyTests        # 유닛 테스트 (Domain 규칙, Reducer TestStore)
└── PlobbyUITests      # UI 테스트
```

- `import Supabase`는 `Clients/` 안에서만 사용합니다.
- DTO는 `Clients/` 밖으로 내보내지 않고, Feature에서는 `Domain/`의 Entity만 사용합니다.
- `Domain/`은 SwiftUI, TCA, Supabase를 import하지 않습니다.
- `Core/`는 특정 Feature를 참조하지 않습니다.

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
