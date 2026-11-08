#Requires -Version 5.1
param([Parameter(Mandatory = $true)][string]$InstallerPath)
$ErrorActionPreference = 'Stop'
$InstallerPath = (Resolve-Path -LiteralPath $InstallerPath).Path
$process = Start-Process -FilePath $InstallerPath -ArgumentList '--verify-payload' -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) { throw "Embedded payload verification failed: $($process.ExitCode)" }
$assembly = [Reflection.Assembly]::LoadFile($InstallerPath)
$setup = $assembly.GetType('Setup')
$flags = [Reflection.BindingFlags]'Static,NonPublic'
$check = $setup.GetMethod('CheckHash', $flags)
$failed = $false
try { $check.Invoke($null, @([byte[]]@(1,2,3), ('0' * 64))) } catch {
    if ($_.Exception.GetBaseException() -isnot [IO.InvalidDataException]) { throw }
    $failed = $true
}
if (-not $failed) { throw 'Corrupt payload was accepted' }
$safePath = $setup.GetMethod('SafePath', $flags)
$root = Join-Path ([IO.Path]::GetTempPath()) 'DestinyInstallerPathTest'
foreach ($bad in @('../outside.txt', '..\outside.txt', 'C:\outside.txt')) {
    $failed = $false
    try { $safePath.Invoke($null, @([string]$root, [string]$bad)) } catch {
        if ($_.Exception.GetBaseException() -isnot [IO.InvalidDataException]) { throw }
        $failed = $true
    }
    if (-not $failed) { throw "Unsafe archive path accepted: $bad" }
}
$valid = $safePath.Invoke($null, @([string]$root, 'Dependencies/x64/test.appx'))
if (-not $valid.StartsWith($root + '\')) { throw 'Valid archive path rejected' }
$certificate = $setup.GetMethod('ReadCertificate', $flags).Invoke($null, @())
try {
    if ($certificate.HasPrivateKey) { throw 'Private certificate embedded' }
    $signature = Get-AuthenticodeSignature -LiteralPath $InstallerPath
    if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint -or
        $signature.Status -eq 'HashMismatch') { throw 'Installer signature does not match MSIX certificate' }
} finally { $certificate.Dispose() }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = [Activator]::CreateInstance($assembly.GetType('SetupWindow'), $true)
try {
    foreach ($control in $form.Controls) {
        if ($control.Right -gt $form.ClientSize.Width -or $control.Bottom -gt $form.ClientSize.Height) {
            throw 'Installer control exceeds window bounds'
        }
    }
} finally { $form.Dispose() }
Write-Output 'PASS: embedded payload/runtime/certificate hashes, corrupt hash rejection, traversal rejection, installer signature and form layout. No installation or certificate import performed.'
