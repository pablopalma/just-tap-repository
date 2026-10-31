# Records the teaser (tools/teaser.tscn, docs/guion-trailer-teaser.md) and exports it.
#   Builds/trailer/just_tap_teaser.mp4         — 16:9, 1080p, -14 LUFS (Steam, X, Reddit)
#   Builds/trailer/just_tap_teaser_square.mp4  — 1:1, 1080×1080, for phones
# Usage: powershell -File tools/make_teaser.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = "C:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe"
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
$out = Join-Path $root "Builds\trailer"
New-Item -ItemType Directory -Force $out | Out-Null
$avi = Join-Path $out "teaser.avi"

# Movie Maker records at the window size: open the window at 1080p only while recording.
$override = Join-Path $root "override.cfg"
"[display]`nwindow/size/window_width_override=1920`nwindow/size/window_height_override=1080`n" | Set-Content -Encoding ascii $override
try {
    & $godot --path $root --write-movie $avi --fixed-fps 60 res://tools/teaser.tscn
} finally {
    Remove-Item $override -ErrorAction SilentlyContinue
}

& $ffmpeg -v error -y -i $avi -vf "scale=in_range=pc:out_range=tv,format=yuv420p" -c:v libx264 -preset slow -crf 18 `
    -af "loudnorm=I=-14:TP=-1.5:LRA=11" -ar 48000 -c:a aac -b:a 192k -movflags +faststart `
    (Join-Path $out "just_tap_teaser.mp4")
# Square: the line and the barriers are always in the middle of the frame.
& $ffmpeg -v error -y -i $avi -vf "crop=1080:1080:420:0,scale=in_range=pc:out_range=tv,format=yuv420p" -c:v libx264 -preset slow -crf 18 `
    -af "loudnorm=I=-14:TP=-1.5:LRA=11" -ar 48000 -c:a aac -b:a 192k -movflags +faststart `
    (Join-Path $out "just_tap_teaser_square.mp4")
Get-ChildItem $out -Filter "just_tap_teaser*.mp4" | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }