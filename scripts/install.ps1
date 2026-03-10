param(
    [string] $BinDir = "${Home}\.nodejs",
    [string] $Version = 'lts',
    [switch] $Update = $false,
    [switch] $NoAddToPath = $false
)
$ErrorActionPreference = 'Stop'

if (!(!(Test-Path $BinDir\*) -or $Update)) {
    Write-Error 'Destination directory not empty, try with -Update instead'
}
if (!(Test-Path $BinDir)) {
    New-Item $BinDir -ItemType Directory -Force | Out-Null
}
$BinDir = Resolve-Path $BinDir

$DistTarget = switch ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE) {
    'AMD64' { 'win-x64.zip' }
    'ARM64' { 'win-arm64.zip' }
    default {
        Write-Error 'NodeJS is only available for x86 64-bit and ARM64 Windows'
    }
}

$Release = $Version.ToLower()
if (($Version -ieq 'lts') -or ($Version -ieq 'latest')) {
    $NODEJS_RELEASES_SCHEDULE = (Invoke-RestMethod 'https://raw.githubusercontent.com/nodejs/Release/main/schedule.json').PSObject.Properties |
        Where-Object { (Get-Date) -le [datetime]$_.Value.end } |
        Where-Object { (Get-Date) -ge [datetime]$_.Value.start } |
        Sort-Object { $_.Value.start } -Descending

    if ($Version -ieq 'lts') {
        $Release = ($NODEJS_RELEASES_SCHEDULE |
                Where-Object { $_.Value.lts -and [datetime]$_.Value.lts -le (Get-Date) } |
                Select-Object -First 1
        ).Value.codename.ToLower()
    }
    if ($Version -ieq 'latest') {
        $Release = ($NODEJS_RELEASES_SCHEDULE |
                Select-Object -First 1
        ).Name.Replace('v', '')
    }
}

$NODEJS_DIST_INDEX = (Invoke-RestMethod 'https://nodejs.org/dist/index.json') | Sort-Object { $_.date } -Descending
$Dist = switch -Regex ($Release) {
    '^[a-z]*$' {
        $NODEJS_DIST_INDEX |
            Where-Object { $_.lts -eq $Release.ToLower() } |
            Select-Object -First 1 -ExpandProperty 'version'
    }
    '^[0-9]*$' {
        $NODEJS_DIST_INDEX |
            Where-Object { $_.version -like "v$Release*" } |
            Select-Object -First 1 -ExpandProperty 'version'
    }
    '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$' {
        $NODEJS_DIST_INDEX |
            Where-Object { $_.version -eq "v$Release" } |
            Select-Object -First 1 -ExpandProperty 'version'
    }
    default {
        Write-Error "Can't parse Version=$Release"
    }
}
if ([string]::IsNullOrEmpty($Dist)) {
    Write-Error "Can't find NodeJS release with version: $Release"
}
$Target = "node-$Dist-$DistTarget"

Push-Location -Path $BinDir
Write-Host "Downloading $Target"
curl.exe -O "https://nodejs.org/dist/$Dist/node-$Dist-$DistTarget"

Write-Host "Unpacking $Target"
tar.exe xf $Target --strip-components=1 -C .
Remove-Item $Target

Write-Host 'Updating npm'
powershell -executionpolicy bypass .\npm install -g npm@latest

Write-Host "Successfully installed in $BinDir"
Pop-Location

if (!$NoAddToPath) {
    $User = [System.EnvironmentVariableTarget]::User
    $Path = [System.Environment]::GetEnvironmentVariable('Path', $User)
    if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
        $Dirs = $Path -split ';' | Where-Object { ![string]::IsNullOrEmpty($_) }
        $Dirs = @($Dirs; $BinDir)
        $Path = $Dirs -join ';'
        $Path += ';'
        [System.Environment]::SetEnvironmentVariable('Path', $Path, $User)
        $Env:Path = $Path
        Remove-Item $BinDir\npm.ps1 -ErrorAction Ignore
        Remove-Item $BinDir\npx.ps1 -ErrorAction Ignore
        Remove-Item $BinDir\install_tools.bat -ErrorAction Ignore
        Write-Output "Added $BinDir to UserPath"
    }
    else {
        Write-Output "Skip adding to PATH, $BinDir already in UserPath"
    }
}