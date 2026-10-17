# Plobby
> 해양 정화 봉사자에게는 꾸준한 활동 동기를, 기관에게는 해양 환경 관리 이력을 한눈에 제공하는 서비스

## 📷 Screenshot
📌 Todo: 추가하기 ~.~

## 🔨 Tech Stack
📌 Todo: 우리 프로젝트에 맞춰 수정하기 ~.~
| Category | Tools & Technologies |
| :--- | :--- |
| **IDE** | Xcode 26.x |
| **Minimum Deployment Target** | iOS 26.4 |
| **Language** | Swift 6 |
| **UI Framework** | SwiftUI |
| **Architecture** | MVI |
| **Concurrency** | Swift Concurrency |
| **Package Manager** | Swift Package Manager (SPM) |

## 🛠️ Architecture
```
📌 Todo: 추가하기 ~.~
```

## 📂 Foldering
```
📌 Todo: 추가하기 ~.~
```

## 📌 Convention
### Code Style
[Swift 스타일쉐어 가이드](https://github.com/StyleShare/swift-style-guide)를 기반으로 하되, 팀원의 기존 스타일과 SwiftUI 프로젝트 특성을 반영하여 일부 규칙은 재정의할 수 있습니다.
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
1. 작업할 내용에 대한 이슈를 판다
2. 이슈 번호를 확인하고, 브랜치 컨벤션에 맞게 **GitHub에서** 브랜치를 판다
   - 반드시 최신 `develop` 브랜치에서 파생해야 함
   - 로컬에서는 `git fetch origin` → `git switch 브랜치이름`으로 이동
3. 작업 내용을 적당히 쪼개어 로컬에서 `commit` 한다
4. 작업이 완료되면 `push` 후 PR을 자세히 작성한다
   - `push` 전 최신 `develop`을 작업 브랜치에 `merge` 하고 빌드되는지 꼭 확인
5. 코드 리뷰 후 모든 개발 팀원의 `approve`를 받으면 `develop`에 `merge` 한다
   - `merge` 후 원격 브랜치는 삭제한다 (로컬은 남겨두는 것이 좋음)
6. `merge` 후 팀원에게 알리고, 모든 팀원은 로컬 `develop`을 최신화한다

## 🧑‍💻 Team Members
| | | | | | |
| :--: | :--: | :--: | :--: | :--: | :--: |
| [김예빈](https://github.com/ErinKYB) | [박정민](https://github.com/LanaKee) | [이선우](https://github.com/dlsundn) | [이은지](https://github.com/oeunji) | 정지나 | [허승준](https://github.com/dev-domo) |
| 에린(Erin) | 라나키(Lanakee) | 신디(Cindy) | 로시(Rossi) | 지나(Jina) | 더스틴(Dustin) |
| Designer | Developer | Designer | Developer | Designer | Developer |
