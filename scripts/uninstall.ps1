param(
    [string] $BinDir = "$(Get-Command node | Split-Path -Parent)"
)
$ErrorActionPreference = 'Stop'

if (!(Test-Path $BinDir\node.exe)) {
    Write-Error "Can't find NodeJS installation, use -BinDir PATH instead"
}
$BinDir = Resolve-Path $BinDir

if (Test-Path $BinDir\npm*) {
    Push-Location $BinDir
    powershell -executionpolicy bypass .\npm cache clean --force --silent
    Pop-Location
    Write-Host 'Cleaned npm cache'
}

@(
    "$env:APPDATA\npm",
    "$env:LOCALAPPDATA\npm",
    "$env:APPDATA\npm-cache",
    "$env:LOCALAPPDATA\npm-cache",
    "$env:USERPROFILE\.node-gyp"
) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item -Path $_ -Recurse -Force
        Write-Host "Removed directory: $_"
    }
}

@(
    "$env:USERPROFILE\npmrc",
    "$env:USERPROFILE\.npmrc",
    "$env:USERPROFILE\.node_repl_history",
    "$env:USERPROFILE\.npm-init.js"
) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item -Path $_ -Force
        Write-Host "Removed file: $_"
    }
}

Get-Item $env:LOCALAPPDATA\Temp\*.* -Include node* | ForEach-Object {
    Remove-Item $_ -Recurse -Force
    Write-Host "Clean temp: $_"
}
Get-Item $env:LOCALAPPDATA\Temp\*.* -Include npm* | ForEach-Object {
    Remove-Item $_ -Recurse -Force
    Write-Host "Clean temp: $_"
}

$User = [System.EnvironmentVariableTarget]::User
$Path = [System.Environment]::GetEnvironmentVariable('Path', $User)
if (";$Path;".ToLower() -like "*;$BinDir;*".ToLower()) {
    $Dirs = ($Path -split ';' | Where-Object { ![string]::IsNullOrEmpty($_) })
    $Dirs = $Dirs | Where-Object { $_ -ne $BinDir }
    $Path = $Dirs -join ';'
    $Path += ';'
    [System.Environment]::SetEnvironmentVariable('Path', $Path, $User)
    Write-Host "Removed $BinDir from UserPath"
}

Remove-Item -Path $BinDir -Recurse -Force -ErrorAction Ignore
$LockedFiles = Get-ChildItem $BinDir -Recurse | ForEach-Object { ( $_.FullName) }
if ($LockedFiles.Length -ne 0) {
    Get-Process | ForEach-Object {
        $processVar = $_; $_.Modules | ForEach-Object {
            if ($LockedFiles -ccontains $_.FileName) {
                Stop-Process -Id $processVar.id
            }
        }
    }
}
if ($LockedFiles) { Remove-Item -Path $BinDir -Recurse -Force -ErrorAction Continue }
Write-Host "Removed installation directory: $BinDir"