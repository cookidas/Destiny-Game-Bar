- [English](#english)
- [한국어](#한국어)

- 
## English
# Destiny2 Game Bar

An unofficial widget for accessing DIM and other Destiny-related websites inside Xbox Game Bar on Windows 11. It uses a single WebView2 instance to navigate between sites and includes a workaround for the mouse drag-and-drop issues found in the standard browser widget.

## Installation

1. Download the ZIP archive from **Releases** and extract it.
2. Run **`install.bat`**.
3. Once installation is complete, press `Win+G` → open the Widget menu → select Destiny Game Bar.

For detailed manual installation instructions, see the [Manual Installation Guide](Release/INSTALL.md).

The current GitHub release is a self-signed preview. Windows may display a warning about an unverified publisher. Certificate registration takes place when you click Install and approve the Windows permission prompt. This is not a Microsoft Store release and is not signed with a publicly trusted code-signing certificate. The signing private key is not distributed.

**Requirements:** Windows 11 x64, Xbox Game Bar, and an internet connection.

After installation, press `Win+G` → open the Widget menu → select **Destiny Game Bar**.

## Features

- Back, forward, and refresh controls
- Website shortcut selection through the ⋮ menu in the upper-right corner
- Favicon shortcuts for selected websites, with your selections saved
- Horizontal scrolling in the shortcut bar when the window is narrow
- Game Bar's built-in widget resizing and pinning
- A mouse drag-and-drop workaround for DIM

DIM, Light.gg, and Destiny Report are selected by default. The widget does not keep hidden tabs open for each website. Clicking a shortcut navigates to that site in the current webview.

| Order | Website | URL |
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

## Sign-in and Storage

Sign in directly on each website. The widget's cookies, cache, and login sessions are stored in its own WebView2 app data, separate from regular Edge or Chrome. Shortcut selections are saved in the Windows app's local settings. The app does not operate a separate account server or include password or token collection features. Each website's own policies apply to its handling of your data.

## Known Issues

- Input response and image rendering may slow down when the game is under heavy load.
- WebView2 memory usage may increase as you navigate between websites. The cause and memory-reclamation behavior are still being investigated.
- The drag-and-drop workaround applies only to mouse input on the top-level DIM page. It does not cover touch dragging or dragging files from outside the webview.
- New-window requests open in the current webview. Some sign-in popups that require `window.opener` still need compatibility testing.
- Windows ARM64 and Windows 10 are not supported by this package.


## License and Attribution

The MIT notice for the portions based on WidgetSampleCS from Microsoft's XboxGameBarSamples is retained in [LICENSE](LICENSE). See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the sources of website favicons and external components. This app is not an official product of Bungie, Microsoft, or any of the linked websites.


## 한국어
# 데스티니 가디언즈 게임바

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

## 로그인과 저장소

각 사이트에서 직접 로그인합니다. 위젯의 쿠키·캐시·로그인 세션은 일반 Edge나 Chrome과 분리된 앱 전용 WebView2 저장소에 저장됩니다. 바로가기 선택은 Windows 앱의 로컬 설정에 저장됩니다. 앱 자체에는 별도 계정 서버나 비밀번호·토큰 수집 기능이 없습니다. 각 웹사이트의 데이터 처리에는 해당 사이트의 정책이 적용됩니다.

## 확인된 이슈

- 게임 부하가 높을 때 입력 반응과 이미지 표시가 느려질 수 있습니다.
- 여러 사이트를 이동하면 WebView2 메모리 사용량이 증가할 수 있습니다. 원인과 메모리 반환 동작은 추가 확인 중입니다.
- 드래그 보정은 최상위 DIM 페이지의 마우스 입력에만 적용됩니다. 터치 드래그나 웹뷰 밖에서 파일을 끌어오는 동작은 보정하지 않습니다.
- 새 창 요청은 현재 웹뷰에서 열립니다. `window.opener`가 필요한 일부 로그인 팝업은 호환성 검증이 필요합니다.
- Windows ARM64와 Windows 10은 이 패키지의 지원 대상이 아닙니다.


## 라이선스와 출처

Microsoft XboxGameBarSamples의 WidgetSampleCS를 기반으로 한 부분의 MIT 고지는 [LICENSE](LICENSE)에 유지합니다. 사이트 파비콘과 외부 구성 요소의 출처는 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)를 참고하세요. 이 앱은 Bungie, Microsoft 또는 연결 사이트의 공식 제품이 아닙니다.
