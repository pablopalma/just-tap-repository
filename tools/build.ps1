# Exports the web and Windows builds and zips each with the version in its name
# (BuildFlags.VERSION), so the uploads can be told apart: Builds/just_tap_web_0.11.1-beta.zip.
# Run from the project folder: powershell -File tools/build.ps1
$ErrorActionPreference = "Stop"
$godot = "C:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$m = Select-String -Path scripts/build_flags.gd -Pattern 'const VERSION := "(.+)"'
if (-not $m) { throw "VERSION not found in scripts/build_flags.gd" }
$version = $m.Matches[0].Groups[1].Value

& $godot --headless --path . --export-release "Web" Builds/web/index.html
& $godot --headless --path . --export-release "Windows" Builds/windows/JustTap.exe
# the export touches project.godot; nothing in it should change
git checkout -- project.godot

Remove-Item Builds/web/*.tmp, Builds/windows/*.tmp -ErrorAction SilentlyContinue
$web = "Builds/just_tap_web_$version.zip"
$win = "Builds/just_tap_windows_$version.zip"
Compress-Archive -Force -Path Builds/web/* -DestinationPath $web
Compress-Archive -Force -Path Builds/windows/* -DestinationPath $win
Get-Item $web, $win | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }, LastWriteTime | Format-Table -AutoSize
