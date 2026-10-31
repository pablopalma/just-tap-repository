# Records the demo trailer (tools/trailer.tscn) and exports it.
#   Builds/trailer/just_tap_trailer.mp4  — 1080p, H.264, loudness -14 LUFS (itch, YouTube, redes)
#   Builds/trailer/just_tap_colour.gif   — the colour coming back, for Reddit
#   Builds/trailer/just_tap_city.gif     — the city building itself in the distance
#   Builds/trailer/just_tap_dark.gif     — the dark: chaos and the crumbling tower
#   Builds/trailer/just_tap_whale.gif    — the celestial whale
# Usage: powershell -File tools/make_trailer.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = "C:\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe"
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

# GIFs for Reddit and the itch page: at most 3 MB, so try smaller sizes and fewer frames until one fits.
function Make-Gif($start, $name, $len = 4.5) {
    $gif = Join-Path $out $name
    foreach ($q in @(@(960, 15, 128), @(800, 15, 128), @(800, 12, 96), @(640, 12, 96), @(560, 10, 64))) {
        & $ffmpeg -v error -y -ss $start -t $len -i $avi -vf "fps=$($q[1]),scale=$($q[0]):-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=$($q[2]):stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" $gif
        if ((Get-Item $gif).Length -le 3MB) { break }
    }
}
Make-Gif 19.0 "just_tap_colour.gif" 4.0   # the colour coming back (bars 6.5–8)
Make-Gif 23.4 "just_tap_city.gif"       # the city building itself, the bird (bars 8–10)
Make-Gif 34.5 "just_tap_dark.gif"       # the dark: chaos and the tower crumbling (bars 11.5–14)
Make-Gif 49.8 "just_tap_whale.gif"      # something awakens: the whale (bars 17.5–19)
Get-ChildItem $out -File | Where-Object { $_.Extension -in ".mp4", ".gif" } | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }