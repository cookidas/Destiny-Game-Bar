#Requires -Version 5.1
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'artifacts'),
    [string]$CertificateThumbprint,
    [string]$PackagePath,
    [string]$CertificatePath,
    [SecureString]$CertificatePassword
)
$ErrorActionPreference = 'Stop'
[xml]$manifest = Get-Content (Join-Path $PSScriptRoot 'DimGameBar/Package.appxmanifest') -Raw
$version = $manifest.Package.Identity.Version
$publisher = $manifest.Package.Identity.Publisher
$identity = $manifest.Package.Identity.Name
$stage = Join-Path ([IO.Path]::GetTempPath()) ('DestinyGameBar-' + [Guid]::NewGuid().ToString('N'))
$packageOutput = Join-Path $stage 'packages'
if ($PackagePath) {
    $packages = @(Get-Item -LiteralPath $PackagePath)
} else {
    & (Join-Path $PSScriptRoot 'Build.ps1') -Configuration Release -PackageOutputDirectory $packageOutput
    $packages = @(Get-ChildItem -LiteralPath $packageOutput -Recurse -File |
        Where-Object { $_.Extension -in @('.appx', '.msix') -and $_.Name.StartsWith($identity + '_') -and
            $_.FullName -notmatch '[\\/]Dependencies[\\/]' })
}
if ($packages.Count -ne 1) { throw 'Release 패키지를 하나로 식별할 수 없습니다.' }
if ($packages[0].Extension -notin @('.appx', '.msix')) { throw 'APPX/MSIX 패키지가 필요합니다.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($packages[0].FullName)
try {
    $reader = [IO.StreamReader]::new($zip.GetEntry('AppxManifest.xml').Open())
    try { [xml]$builtManifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
} finally { $zip.Dispose() }
if ($builtManifest.Package.Identity.Name -ne $identity -or $builtManifest.Package.Identity.Publisher -ne $publisher -or
    $builtManifest.Package.Identity.Version -ne $version -or $builtManifest.Package.Identity.ProcessorArchitecture -ne 'x64') {
    throw '패키지의 ID, 게시자, 버전 또는 아키텍처가 소스 매니페스트와 다릅니다.'
}

# Signing keys stay outside the payload; only the public certificate is exported.
if ($CertificatePath) {
    if (-not $CertificatePassword) { throw '-CertificatePath에는 -CertificatePassword가 필요합니다.' }
    $plainPassword = [Net.NetworkCredential]::new('', $CertificatePassword).Password
    $cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
        [IO.Path]::GetFullPath($CertificatePath), $plainPassword,
        [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
} elseif ($CertificateThumbprint) {
    $cert = Get-Item -LiteralPath ('Cert:\CurrentUser\My\' + $CertificateThumbprint)
} else {
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object {
        $_.FriendlyName -eq 'Destiny Game Bar local releases' -and $_.Subject -eq $publisher -and
        $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date).AddDays(30)
    } | Sort-Object NotAfter -Descending | Select-Object -First 1
    if (-not $cert) {
        $certArgs = @{
            Type = 'Custom'; Subject = $publisher; KeyUsage = 'DigitalSignature'
            CertStoreLocation = 'Cert:\CurrentUser\My'; KeyExportPolicy = 'NonExportable'
            TextExtension = @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
            FriendlyName = 'Destiny Game Bar local releases'; NotAfter = (Get-Date).AddYears(3)
        }
        $cert = New-SelfSignedCertificate @certArgs
    }
}
if ($cert.Subject -ne $publisher -or -not $cert.HasPrivateKey -or $cert.NotAfter -le (Get-Date)) {
    throw '인증서의 Subject, 개인키 및 유효기간을 확인하세요.'
}
[xml]$project = Get-Content (Join-Path $PSScriptRoot 'DimGameBar/DimGameBar.csproj') -Raw
$sdkVersion = $project.SelectSingleNode("//*[local-name()='TargetPlatformVersion']").InnerText
$signTool = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) "Windows Kits\10\bin\$sdkVersion\x64\signtool.exe"
if (-not (Test-Path -LiteralPath $signTool)) { throw "SignTool을 찾을 수 없습니다: $signTool" }

$payload = Join-Path $stage "DestinyGameBar_${version}_x64"
New-Item -ItemType Directory -Path $payload -Force | Out-Null
$package = Join-Path $payload ("DestinyGameBar_${version}_x64" + $packages[0].Extension)
Copy-Item -LiteralPath $packages[0].FullName -Destination $package
$signArgs = @('sign', '/fd', 'SHA256')
if ($CertificatePath) {
    $signArgs += @('/f', [IO.Path]::GetFullPath($CertificatePath), '/p', $plainPassword)
} else {
    $signArgs += @('/sha1', $cert.Thumbprint, '/s', 'My')
}
& $signTool @signArgs $package
if ($LASTEXITCODE -ne 0) { throw '패키지 서명에 실패했습니다.' }
Export-Certificate -Cert $cert -FilePath (Join-Path $payload 'DestinyGameBar.cer') | Out-Null
$dependencies = Join-Path $packages[0].DirectoryName 'Dependencies/x64'
if (Test-Path -LiteralPath $dependencies) {
    $dependencyOutput = Join-Path $payload 'Dependencies'
    New-Item -ItemType Directory -Path $dependencyOutput -Force | Out-Null
    Copy-Item -LiteralPath $dependencies -Destination $dependencyOutput -Recurse
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Release/Install.ps1') -Destination $payload
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Release/INSTALL.md') -Destination (Join-Path $payload 'README.md')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'LICENSE') -Destination $payload
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'THIRD-PARTY-NOTICES.md') -Destination $payload
$signingKind = if ($cert.Subject -eq $cert.Issuer) { 'self-signed' } else { 'certificate-signed' }
@"
Destiny Game Bar $version / Release x64 / Windows 11
Publisher: $publisher
Certificate SHA1 thumbprint: $($cert.Thumbprint)
Certificate SHA256: $((Get-FileHash (Join-Path $payload 'DestinyGameBar.cer') -Algorithm SHA256).Hash)
Certificate expires: $($cert.NotAfter.ToString('yyyy-MM-dd'))
Signing: $signingKind; self-signed packages require explicit certificate trust before installation.
No private key is distributed. Certificate trust is not installed by this build script.
"@ | Set-Content -LiteralPath (Join-Path $payload 'RELEASE-INFO.txt') -Encoding UTF8
$hashes = Get-ChildItem -LiteralPath $payload -Recurse -File | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($payload.Length + 1).Replace('\', '/')
    "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $relative"
}
$hashes | Set-Content -LiteralPath (Join-Path $payload 'SHA256SUMS.txt') -Encoding UTF8
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$archive = Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) "DestinyGameBar_${version}_x64.zip"
Compress-Archive -Path (Join-Path $payload '*') -DestinationPath $archive -Force -ErrorAction Stop
(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($archive) |
    Set-Content -LiteralPath ($archive + '.sha256') -Encoding UTF8
Write-Host "Release ZIP: $archive"
