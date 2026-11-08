#Requires -Version 5.1
param([Parameter(Mandatory = $true)][string]$ArchivePath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Security
$temp = Join-Path ([IO.Path]::GetTempPath()) ('DestinyReleaseTest-' + [Guid]::NewGuid().ToString('N'))
Expand-Archive -LiteralPath $ArchivePath -DestinationPath $temp -ErrorAction Stop
$hashLines = @(Get-Content (Join-Path $temp 'SHA256SUMS.txt') | Where-Object { $_.Trim() })
foreach ($line in $hashLines) {
    if ($line -notmatch '^([a-f0-9]{64})  (.+)$') { throw 'Invalid checksum entry' }
    $expected = $Matches[1]
    $path = [IO.Path]::GetFullPath((Join-Path $temp $Matches[2]))
    if (-not $path.StartsWith($temp + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid checksum path' }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected) { throw "Checksum mismatch: $path" }
}
$files = @(Get-ChildItem -LiteralPath $temp -Recurse -File)
if ($hashLines.Count -ne $files.Count - 1) { throw 'Unlisted release files' }
if ($files | Where-Object Extension -in @('.pfx', '.key', '.pem', '.pdb', '.cs')) { throw 'Private/build/source files in installer ZIP' }
$certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new((Join-Path $temp 'DestinyGameBar.cer'))
if ($certificate.HasPrivateKey) { throw 'Private key included in release certificate' }

function Read-PackageManifest($path) {
    $zip = [IO.Compression.ZipFile]::OpenRead($path)
    try {
        $reader = [IO.StreamReader]::new($zip.GetEntry('AppxManifest.xml').Open())
        try { [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
    } finally { $zip.Dispose() }
}
$package = @(Get-ChildItem -LiteralPath $temp -Filter 'DestinyGameBar_*.msix')
if ($package.Count -ne 1) { throw 'Expected one MSIX' }
$manifest = Read-PackageManifest $package[0].FullName
if ($manifest.Package.Identity.ProcessorArchitecture -ne 'x64' -or $manifest.Package.Identity.Publisher -ne $certificate.Subject) {
    throw 'Unexpected package architecture or publisher'
}
$dependencyManifests = @(Get-ChildItem (Join-Path $temp 'Dependencies/x64') -Filter '*.appx' | ForEach-Object { Read-PackageManifest $_.FullName })
foreach ($required in $manifest.Package.Dependencies.PackageDependency) {
    if (-not ($dependencyManifests | Where-Object {
        $_.Package.Identity.Name -eq $required.Name -and [version]$_.Package.Identity.Version -ge [version]$required.MinVersion -and
        $_.Package.Identity.Publisher -eq $required.Publisher
    })) { throw "Missing framework dependency: $($required.Name)" }
}
$zip = [IO.Compression.ZipFile]::OpenRead($package[0].FullName)
try {
    $signature = [IO.MemoryStream]::new()
    $stream = $zip.GetEntry('AppxSignature.p7x').Open()
    try { $stream.CopyTo($signature) } finally { $stream.Dispose() }
    $bytes = $signature.ToArray()
    $cms = [Security.Cryptography.Pkcs.SignedCms]::new()
    $cms.Decode([byte[]]$bytes[4..($bytes.Length - 1)])
    $cms.CheckSignature($true)
    if ($cms.SignerInfos[0].Certificate.Thumbprint -ne $certificate.Thumbprint) { throw 'Signer certificate mismatch' }
    if (@($zip.Entries | Where-Object FullName -like 'Assets/*Favicon.png').Count -ne 10) { throw 'Missing packaged favicons' }
} finally { $zip.Dispose() }
Write-Output "PASS: release checksums, MSIX signature, public certificate, 10 favicons, all framework dependencies; version $($manifest.Package.Identity.Version)"
