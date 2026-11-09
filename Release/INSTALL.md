# Destiny Game Bar 1.0.2 설치

Windows 11 x64용 배포판입니다. Xbox Game Bar와 Microsoft Edge WebView2 Runtime이 필요합니다.

## 설치 및 업데이트

1. ZIP의 모든 파일을 같은 폴더에 압축 해제합니다.
2. 실행 중인 Destiny Game Bar 위젯을 닫습니다.
3. **install.bat**을 실행하고 인증서 등록을 위한 Windows 관리자 권한 요청을 승인합니다. 오류가 나면 창에 표시되는 내용을 확인하세요.
4. 완료 후 **Win+G → 위젯 메뉴 → Destiny Game Bar**를 엽니다. 위젯 메뉴에서 별표를 누르면 즐겨찾기로 지정할 수 있습니다.
5. 우측 상단 **⋮** 메뉴에서 **Godroll.tv**를 체크하면 상단에 바로가기 아이콘이 표시됩니다.

BAT은 공개 인증서를 로컬 컴퓨터의 TrustedPeople 저장소에 등록한 뒤, 원래 Windows 사용자 계정으로 앱 패키지를 설치합니다. 이 BAT은 공용 런타임 의존성을 재설치하지 않습니다. 기존 1.0.1 설치가 있다면 앱을 제거하지 않고 업데이트하세요. 앱 식별자와 서명 인증서는 유지됩니다.

## 수동 설치

인증서를 처음 등록할 때는 관리자 권한 PowerShell에서 실행합니다.

```powershell
Import-Certificate -FilePath .\DestinyGameBar.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

위젯을 닫고, 설치할 Windows 사용자의 일반 PowerShell에서 실행합니다.

```powershell
Add-AppxPackage -Path .\DestinyGameBar_1.0.2.0_x64.msix
```

처음 설치하는 PC에서 프레임워크 의존성 누락 오류가 발생하면 동봉된 Dependencies/x64가 필요합니다. 인증서를 등록한 뒤 아래 명령으로 동봉된 의존성과 앱을 함께 설치할 수 있습니다. 공용 런타임을 사용 중인 앱이 있으면 설치가 보류될 수 있으므로 해당 앱을 닫고 다시 시도하세요.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

## 인증서와 제거

자체 서명된 배포판이므로 Windows 게시자 경고가 표시될 수 있습니다. 배포자를 신뢰할 때만 인증서를 등록하세요. 인증서 정보와 해시는 RELEASE-INFO.txt 및 SHA256SUMS.txt에 있습니다. 공개 인증서만 포함되며 개인키는 배포하지 않습니다.

제거하려면 Windows 설정 → 앱 → 설치된 앱 → Destiny Game Bar → 제거를 사용하세요. 제거하면 로그인 세션과 설정이 지워질 수 있습니다.
