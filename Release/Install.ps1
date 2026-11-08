#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$packages = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object {
    $_.Name -like 'DestinyGameBar_*' -and $_.Extension -in @('.appx', '.msix')
})
if ($packages.Count -ne 1) { throw '설치 폴더에 DestinyGameBar APPX/MSIX 파일이 정확히 하나 있어야 합니다.' }
$dependencyDir = Join-Path $PSScriptRoot 'Dependencies/x64'
$installArgs = @{ Path = $packages[0].FullName }
if (Test-Path -LiteralPath $dependencyDir) {
    $dependencies = @(Get-ChildItem -LiteralPath $dependencyDir -Filter '*.appx' -File)
    if ($dependencies.Count) { $installArgs.DependencyPath = [string[]]$dependencies.FullName }
}
try {
    Add-AppxPackage @installArgs
} catch {
    throw "설치 실패: $($_.Exception.Message) 설치 안내의 인증서 등록과 Windows 11 x64 요구 사항을 확인하세요."
}
Write-Host '설치 완료. Win+G → 위젯 메뉴 → Destiny Game Bar를 여세요.'
