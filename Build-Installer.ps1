#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ArchivePath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'artifacts'),
    [string]$CertificatePath,
    [SecureString]$CertificatePassword
)
$ErrorActionPreference = 'Stop'
$ArchivePath = (Resolve-Path -LiteralPath $ArchivePath).Path
& (Join-Path $PSScriptRoot 'Tests/Test-Release.ps1') -ArchivePath $ArchivePath
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
try {
    $entry = $zip.GetEntry('DestinyGameBar.cer')
    $memory = [IO.MemoryStream]::new()
    $stream = $entry.Open()
    try { $stream.CopyTo($memory); $certificateBytes = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
    $package = @($zip.Entries | Where-Object FullName -match '^DestinyGameBar_([\d.]+)_x64\.msix$')
    if ($package.Count -ne 1) { throw 'MSIX 패키지를 하나로 식별할 수 없습니다.' }
    $version = [regex]::Match($package[0].FullName, '[\d]+\.[\d]+\.[\d]+\.[\d]+').Value
} finally { $zip.Dispose() }
$cache = Join-Path $PSScriptRoot 'artifacts/installer'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
$runtime = Join-Path $cache 'MicrosoftEdgeWebview2Setup.exe'
if (-not (Test-Path -LiteralPath $runtime)) {
    Invoke-WebRequest 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $runtime -UseBasicParsing
}
$runtimeSignature = Get-AuthenticodeSignature -LiteralPath $runtime
if ($runtimeSignature.Status -ne 'Valid' -or $runtimeSignature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
    throw 'Microsoft WebView2 설치 도구의 서명을 확인할 수 없습니다.'
}
$stage = Join-Path ([IO.Path]::GetTempPath()) ('DestinyInstaller-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$cer = Join-Path $stage 'DestinyGameBar.cer'
[IO.File]::WriteAllBytes($cer, $certificateBytes)
$payloadHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash
$certificateHash = (Get-FileHash -LiteralPath $cer -Algorithm SHA256).Hash
$runtimeHash = (Get-FileHash -LiteralPath $runtime -Algorithm SHA256).Hash
$info = Join-Path $stage 'BuildInfo.cs'
@"
using System.Reflection;
[assembly: AssemblyTitle("Destiny Game Bar Setup")]
[assembly: AssemblyProduct("Destiny Game Bar")]
[assembly: AssemblyVersion("$version")]
[assembly: AssemblyFileVersion("$version")]
internal static class BuildInfo {
 public const string Version = "$version";
 public const string PayloadSha256 = "$payloadHash";
 public const string CertificateSha256 = "$certificateHash";
 public const string RuntimeSha256 = "$runtimeHash";
}
"@ | Set-Content -LiteralPath $info -Encoding UTF8
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$exe = Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) "DestinyGameBar_${version}_Setup.exe"
$compiler = Join-Path ([Environment]::GetFolderPath('Windows')) 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
& $compiler /nologo /target:winexe /platform:x64 /optimize+ "/out:$exe" "/win32manifest:$(Join-Path $PSScriptRoot 'Installer/app.manifest')" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll "/resource:$ArchivePath,DestinyGameBar.Payload" "/resource:$cer,DestinyGameBar.Certificate" "/resource:$runtime,DestinyGameBar.WebView2Setup" (Join-Path $PSScriptRoot 'Installer/Setup.cs') $info
if ($LASTEXITCODE -ne 0) { throw '설치 EXE 컴파일에 실패했습니다.' }
if ($CertificatePath) {
    if (-not $CertificatePassword) { throw '-CertificatePassword가 필요합니다.' }
    $plainPassword = [Net.NetworkCredential]::new('', $CertificatePassword).Password
    $signer = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
        [IO.Path]::GetFullPath($CertificatePath), $plainPassword,
        [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
    try {
        $expected = [Security.Cryptography.X509Certificates.X509Certificate2]::new($certificateBytes)
        if ($signer.Thumbprint -ne $expected.Thumbprint) { throw 'EXE와 MSIX의 서명 인증서가 다릅니다.' }
        [xml]$project = Get-Content (Join-Path $PSScriptRoot 'DimGameBar/DimGameBar.csproj') -Raw
        $sdk = $project.SelectSingleNode("//*[local-name()='TargetPlatformVersion']").InnerText
        $signTool = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) "Windows Kits\10\bin\$sdk\x64\signtool.exe"
        & $signTool sign /fd SHA256 /f ([IO.Path]::GetFullPath($CertificatePath)) /p $plainPassword $exe
        if ($LASTEXITCODE -ne 0) { throw '설치 EXE 서명에 실패했습니다.' }
    } finally { $signer.Dispose() }
}
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($exe))" | Set-Content -LiteralPath ($exe + '.sha256') -Encoding UTF8
Write-Host "Installer EXE: $exe"
