# Destiny Game Bar

Windows 11의 Xbox Game Bar 안에서 DIM과 데스티니 관련 사이트를 이용할 수 있는 비공식 위젯입니다. 하나의 WebView2에서 사이트를 이동하며, 기본 브라우저 위젯에서 발생하는 마우스 드래그·드롭 문제를 보완하는 코드를 포함합니다.

## 설치

1. **Releases**에서 ZIP 파일을 다운로드하고 압축을 해제하세요.
2. **`install.bat`**을 실행하세요.
3. 설치가 완료되면 `Win+G` → 위젯 메뉴 → Destiny Game Bar를 엽니다.

자세한 수동 설치 절차는 [수동 설치 안내](Release/INSTALL.md)를 참고하세요.

현재 GitHub 배포판은 자체 서명된 프리뷰입니다. Windows에서 확인되지 않은 게시자에 대한 경고가 표시될 수 있습니다. 설치를 시작하고 Windows 관리자 권한 요청을 승인하면 인증서 등록이 진행됩니다. Microsoft Store 배포판이나 공인 코드 서명 인증서로 서명된 배포판은 아닙니다. 서명 개인키는 배포하지 않습니다.

**필요 환경:** Windows 11 x64, Xbox Game Bar, 인터넷 연결.

설치 후 `Win+G` → 위젯 메뉴 → **Destiny Game Bar**를 엽니다.

## 기능

- 뒤로 가기·앞으로 가기·새로고침
- 우측 상단 ⋮ 메뉴에서 사이트별 바로가기 선택
- 선택한 사이트의 파비콘만 상단에 표시하고 선택 상태 저장
- 창이 좁을 때 바로가기 영역 가로 스크롤
- Game Bar의 기본 위젯 크기 변경·고정 기능 사용
- DIM의 마우스 드래그·드롭 보정

처음에는 DIM, Light.gg, Destiny Report가 선택되어 있습니다. 사이트별로 숨은 탭을 열어 두지 않으며, 바로가기를 누르면 현재 웹뷰에서 해당 사이트로 이동합니다.

| 순서 | 사이트 | 주소 |
|---|---|---|
| 1 | DIM | https://app.destinyitemmanager.com/ |
| 2 | Light.gg | https://www.light.gg/ |
| 3 | Destiny Report | https://destiny.report/ |
| 4 | D2ArmorPicker | https://d2armorpicker.com/ |
| 5 | Raid Report | https://raid.report/ |
| 6 | Bray.Tech | https://bray.tech/ |
| 7 | Blueberries.gg | https://www.blueberries.gg/ |
| 8 | Engram.Blue | https://engram.blue/ |
| 9 | Guardian.Report | https://guardian.report/ |
| 10 | DestinyTracker | https://destinytracker.com/ |
| 11 | Godroll.tv | https://godroll.tv/ |

## 로그인과 저장소

각 사이트에서 직접 로그인합니다. 위젯의 쿠키·캐시·로그인 세션은 일반 Edge나 Chrome과 분리된 앱 전용 WebView2 저장소에 저장됩니다. 바로가기 선택은 Windows 앱의 로컬 설정에 저장됩니다. 앱 자체에는 별도 계정 서버나 비밀번호·토큰 수집 기능이 없습니다. 각 웹사이트의 데이터 처리에는 해당 사이트의 정책이 적용됩니다.

## 알려진 제한

- 게임 부하가 높을 때 입력 반응과 이미지 표시가 느려질 수 있습니다.
- 여러 사이트를 이동하면 WebView2 메모리 사용량이 증가할 수 있습니다. 원인과 메모리 반환 동작은 추가 확인 중입니다.
- 드래그 보정은 최상위 DIM 페이지의 마우스 입력에만 적용됩니다. 터치 드래그나 웹뷰 밖에서 파일을 끌어오는 동작은 보정하지 않습니다.
- 새 창 요청은 현재 웹뷰에서 열립니다. `window.opener`가 필요한 일부 로그인 팝업은 호환성 검증이 필요합니다.
- Windows ARM64와 Windows 10은 이 패키지의 지원 대상이 아닙니다.

## 소스에서 빌드

Visual Studio 2022 이상과 C# UWP/.NET Native 도구, Windows SDK **10.0.26100.0**, Release 빌드용 C++ x64 도구가 필요합니다. NuGet 패키지 복원에는 인터넷 연결이 필요합니다. 일반 .NET SDK의 `dotnet build`만으로는 빌드할 수 없습니다.

```powershell
.\Build.ps1 -Configuration Debug
```

또는 `DimGameBar.sln`을 열어 Debug/x64 구성으로 빌드한 뒤, 개발자 모드가 활성화된 PC에서 프로젝트를 우클릭하고 배포(Deploy)를 실행합니다. 표시 이름은 Destiny Game Bar이며, 기존 설치와의 연속성을 유지하기 위해 내부 프로젝트·패키지 식별자는 DimGameBar를 사용합니다.

## 라이선스와 출처

Microsoft XboxGameBarSamples의 WidgetSampleCS를 기반으로 한 부분의 MIT 고지는 [LICENSE](LICENSE)에 유지합니다. 사이트 파비콘과 외부 구성 요소의 출처는 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)를 참고하세요. 이 앱은 Bungie, Microsoft 또는 연결 사이트의 공식 제품이 아닙니다.
