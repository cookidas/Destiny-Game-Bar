param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    [string]$PackageOutputDirectory
)

$ErrorActionPreference = 'Stop'
$programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
$msbuild = (Get-Command MSBuild.exe -ErrorAction SilentlyContinue).Source
if (-not $msbuild) {
    $vswhere = Join-Path $programFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $msbuild = & $vswhere -latest -products * -find 'MSBuild\**\Bin\MSBuild.exe' |
            Select-Object -First 1
    }
}
if (-not $msbuild) {
    throw 'Visual Studio의 UWP 빌드 도구가 필요합니다. README.md의 준비 항목을 먼저 설치하세요.'
}
$buildArgs = @((Join-Path $PSScriptRoot 'DimGameBar/DimGameBar.csproj'), '/restore', '/t:Build', '/v:minimal', '/nologo',
    "/p:Configuration=$Configuration", '/p:Platform=x64', '/p:AppxPackageSigningEnabled=false')
if ($PackageOutputDirectory) {
    $packageDir = [IO.Path]::GetFullPath($PackageOutputDirectory).TrimEnd('\') + '\'
    $buildArgs += @('/p:GenerateAppxPackageOnBuild=true', '/p:UapAppxPackageBuildMode=SideloadOnly',
        "/p:AppxPackageDir=$packageDir")
}
& $msbuild @buildArgs
if ($LASTEXITCODE -ne 0) { throw "빌드 실패: MSBuild 종료 코드 $LASTEXITCODE" }
Write-Host "$Configuration / x64 빌드 완료."
