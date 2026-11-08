# Destiny Game Bar ZIP 수동 설치

Windows 11 x64용 GitHub 프리뷰 배포판입니다. Xbox Game Bar와 Microsoft Edge WebView2 Runtime이 필요합니다. Visual Studio는 필요하지 않습니다.

수동 절차 없이 설치하려면 GitHub Releases의 `DestinyGameBar_1.0.1.0_Setup.exe`를 실행하고 설치 버튼과 필요한 Windows 권한 요청을 승인하세요. 아래 절차는 ZIP으로 설치할 때만 필요합니다.

## 1. 압축 해제

ZIP의 모든 파일을 같은 폴더에 풀어 주세요. MSIX/APPX, Dependencies, 공개 인증서, Install.ps1을 함께 둡니다.

## 2. 공개 인증서 등록 — 최초 설치

이 패키지는 자체 서명되어 있으므로 배포자를 신뢰할 때만 인증서를 등록하세요. 인증서 정보는 RELEASE-INFO.txt, 파일 해시는 SHA256SUMS.txt에 있습니다. 공개 인증서만 포함되며 개인키는 배포하지 않습니다.

압축을 푼 폴더에서 **관리자 권한 Windows PowerShell**을 열고 실행합니다.

```powershell
Import-Certificate -FilePath .\DestinyGameBar.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

이 명령은 이 인증서를 PC의 신뢰할 수 있는 사용자 인증서 저장소에 등록합니다. 설치 스크립트는 인증서를 자동 등록하지 않습니다.

## 3. 앱 설치

Game Bar의 Destiny Game Bar 위젯을 닫으세요. 설치할 Windows 사용자 계정의 일반 PowerShell에서 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

ExecutionPolicy 옵션은 이번 PowerShell 프로세스에만 적용됩니다. 스크립트는 동봉된 x64 의존성과 앱을 설치합니다. 개발자 모드나 시스템 정책을 변경하지 않습니다.

## 4. 위젯 열기

`Win+G` → 위젯 메뉴 → **Destiny Game Bar**를 엽니다. DIM 로그인은 위젯 안에서 직접 진행합니다. 일반 브라우저의 로그인 정보와는 별개입니다. 우측 상단 ⋮ 메뉴에서 바로가기를 선택할 수 있습니다.

## 업데이트·제거

- 업데이트: 위젯을 닫고 같은 배포자의 더 높은 버전 패키지로 Install.ps1을 다시 실행합니다.
- 같은 버전의 개발용 앱이 이미 설치되어 있다면 Windows가 설치를 거부할 수 있습니다. 이를 해결하기 위해 앱을 제거하면 로그인 세션과 설정이 지워질 수 있습니다.
- 제거: Windows 설정 → 앱 → 설치된 앱 → Destiny Game Bar → 제거.
- 인증서를 더 이상 사용하지 않으면 RELEASE-INFO.txt의 지문과 일치하는 인증서만 로컬 컴퓨터의 신뢰할 수 있는 사용자 저장소에서 제거하세요.

## 제한

게임 부하가 높을 때 입력·이미지 표시가 느려질 수 있고, 여러 사이트를 이동하면 메모리가 증가할 수 있습니다. 현재 터치 드래그 보정은 지원하지 않습니다. 비공식 앱이며 Bungie·Microsoft 및 연결 사이트의 공식 제품이 아닙니다.

[Microsoft 자체 서명 패키지 안내](https://learn.microsoft.com/windows/msix/package/create-certificate-package-signing)
