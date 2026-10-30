# Records the demo trailer (tools/trailer.tscn) and exports it.
#   Builds/trailer/just_tap_trailer.mp4  — 1080p, H.264, loudness -14 LUFS (itch, YouTube, redes)
#   Builds/trailer/just_tap_colour.gif   — the colour coming back, for Reddit
# Usage: powershell -File tools/make_trailer.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = "C:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe"
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe | Select-Object -First 1 -ExpandProperty FullName
}
$out = Join-Path $root "Builds\trailer"
New-Item -ItemType Directory -Force $out | Out-Null
$avi = Join-Path $out "trailer.avi"

# Movie Maker records at the window size: open the window at 1080p only while recording.
$override = Join-Path $root "override.cfg"
"[display]`nwindow/size/window_width_override=1920`nwindow/size/window_height_override=1080`n" | Set-Content -Encoding ascii $override
try {
    & $godot --path $root --write-movie $avi --fixed-fps 60 res://tools/trailer.tscn
} finally {
    Remove-Item $override -ErrorAction SilentlyContinue
}

& $ffmpeg -v error -y -i $avi -vf "scale=in_range=pc:out_range=tv,format=yuv420p" -c:v libx264 -preset slow -crf 18 `
    -af "loudnorm=I=-14:TP=-1.5:LRA=11" -ar 48000 -c:a aac -b:a 192k -movflags +faststart `
    (Join-Path $out "just_tap_trailer.mp4")

# The colour coming back (about 15.5–20.5 s), 960 px, 20 fps, its own palette.
& $ffmpeg -v error -y -ss 15.5 -t 5 -i $avi -vf "fps=20,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=192[p];[b][p]paletteuse=dither=sierra2_4a" `
    (Join-Path $out "just_tap_colour.gif")

Get-ChildItem $out -File | Where-Object { $_.Extension -in ".mp4", ".gif" } | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }