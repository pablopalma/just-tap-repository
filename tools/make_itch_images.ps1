# Images for the itch.io page (docs/itch-page.md), taken from the 1080p trailer.
# Needs Builds/trailer/just_tap_trailer.mp4 (tools/make_trailer.ps1). Output: Builds/itch/
# Usage: powershell -File tools/make_itch_images.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe | Select-Object -First 1 -ExpandProperty FullName
}
$video = "Builds/trailer/just_tap_trailer.mp4"
$out = "Builds/itch"
Push-Location $root  # relative paths keep drawtext's font paths free of drive-letter colons
try {
    New-Item -ItemType Directory -Force $out | Out-Null
    $ink = "0x3b3835"
    $title = "fontfile=fonts/CormorantGaramond.ttf:fontcolor=$ink"
    $tag = "fontfile=fonts/CormorantGaramond-Italic.ttf:fontcolor=$ink@0.8"

    # Screenshots: the colour coming back, the star, the bird, the branches, the dark, the city.
    $shots = @(17.5, 28.0, 33.0, 38.5, 42.5, 51.0)
    for ($i = 0; $i -lt $shots.Count; $i++) {
        & $ffmpeg -v error -y -ss $shots[$i] -i $video -frames:v 1 "$out/screenshot_$($i + 1).png"
    }

    # Cover 630x500: the whole city (after the subtitle is gone), with the title over it.
    & $ffmpeg -v error -y -ss 53.6 -i $video -frames:v 1 -vf (
        "scale=-1:620,crop=630:500:(iw-630)/2:30," +
        "drawbox=x=0:y=0:w=630:h=150:color=0xebe6de@0.82:t=fill," +
        "drawtext=${title}:text='just tap':fontsize=78:x=(w-text_w)/2:y=22," +
        "drawtext=${tag}:text='if you had a bad day...':fontsize=26:x=(w-text_w)/2:y=106"
    ) "$out/cover.png"

    # Banner 960x300: a strip of the city behind the title.
    & $ffmpeg -v error -y -ss 53.6 -i $video -frames:v 1 -vf (
        "scale=960:-1,crop=960:300:0:130," +
        "drawbox=x=0:y=0:w=960:h=300:color=0xebe6de@0.8:t=fill," +
        "drawtext=${title}:text='just tap':fontsize=104:x=(w-text_w)/2:y=62," +
        "drawtext=${tag}:text='if you had a bad day...':fontsize=30:x=(w-text_w)/2:y=190"
    ) "$out/banner.png"

    # Paper texture for the page background (fine grain, tiles without visible seams).
    & $ffmpeg -v error -y -f lavfi -i "color=c=0xebe6de:s=256x256,noise=alls=7:allf=u" -frames:v 1 "$out/paper_tile.png"

    # GIFs for the description, one per mechanic, each at most 3 MB (itch's limit for this page).
    # Starts at 640 px; if a GIF is too heavy it is made again with fewer frames, pixels or colours.
    $maxBytes = 3MB - 64KB
    $gifs = [ordered]@{
        "gif_colour" = @(15.5, 5.0)   # the colour comes back
        "gif_star"   = @(26.0, 4.6)   # a star circuit fills, spins up and bursts
        "gif_bird"   = @(31.6, 2.6)   # the giant bird passes close
        "gif_forks"  = @(34.4, 5.4)   # the line splits in two, then three
        "gif_dark"   = @(40.1, 5.0)   # the dark comes in, the line cracks
        "gif_city"   = @(47.5, 5.6)   # everything you built
    }
    # [fps, width, colours], lightest last
    $ladder = @(@(15, 640, 128), @(12, 640, 112), @(10, 600, 96), @(10, 540, 80), @(8, 500, 72), @(8, 440, 64))
    foreach ($name in $gifs.Keys) {
        $start, $len = $gifs[$name]
        foreach ($step in $ladder) {
            $fps, $w, $cols = $step
            & $ffmpeg -v error -y -ss $start -t $len -i $video -vf (
                "fps=$fps,scale=${w}:-1:flags=lanczos,split[a][b];" +
                "[a]palettegen=max_colors=${cols}:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle"
            ) "$out/$name.gif"
            if ((Get-Item "$out/$name.gif").Length -le $maxBytes) { break }
        }
    }
    # The big GIF for Reddit stays with the trailer, not here.
    Remove-Item "$out/just_tap_colour.gif" -ErrorAction SilentlyContinue
    Get-ChildItem $out | Select-Object Name, @{ n = "KB"; e = { [math]::Round($_.Length / 1KB) } }
} finally {
    Pop-Location
}
