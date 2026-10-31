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
    Remove-Item "$out/screenshot_*.png", "$out/gif_*.gif" -ErrorAction SilentlyContinue  # no leftovers from older cuts
    $ink = "0x3b3835"
    $title = "fontfile=fonts/CormorantGaramond.ttf:fontcolor=$ink"
    $tag = "fontfile=fonts/CormorantGaramond-Italic.ttf:fontcolor=$ink@0.8"

    # Times follow the 57 s trailer (docs/trailer.md: 20 bars of 2.857 s).
    # Screenshots: the colour coming back, the city building itself, the star, the bird, the
    # branches, the dark, the golden mandala, the whale.
    $shots = @(17.5, 21.0, 24.5, 27.0, 29.2, 35.0, 44.5, 48.5)
    for ($i = 0; $i -lt $shots.Count; $i++) {
        & $ffmpeg -v error -y -ss $shots[$i] -i $video -frames:v 1 "$out/screenshot_$($i + 1).png"
    }

    # Cover 630x500 and banner 960x300 come from the key art, an illustration of its own
    # (tools/key_art.py, tools/make_capsules.py, docs/capsulas.md).
    Copy-Item "Builds/capsule/itch/cover.png" "$out/cover.png" -Force
    Copy-Item "Builds/capsule/itch/banner.png" "$out/banner.png" -Force
    # Paper texture for the page background (fine grain, tiles without visible seams).
    & $ffmpeg -v error -y -f lavfi -i "color=c=0xebe6de:s=256x256,noise=alls=7:allf=u" -frames:v 1 "$out/paper_tile.png"

    # GIFs for the description, one per mechanic, each at most 3 MB (itch's limit for this page).
    # Starts at 640 px; if a GIF is too heavy it is made again with fewer frames, pixels or colours.
    $maxBytes = 3MB - 64KB
    $gifs = [ordered]@{
        "gif_colour"  = @(15.5, 4.5)   # the colour comes back
        "gif_tree"    = @(11.5, 2.7)   # the upgrade tree opens, node by node
        "gif_build"   = @(20.1, 2.7)   # far back: the city builds itself, piece by piece
        "gif_star"    = @(22.95, 2.7)  # a star circuit spins
        "gif_bird"    = @(25.75, 2.7)  # the giant bird passes close
        "gif_forks"   = @(28.65, 1.3)  # the line splits in three
        "gif_dark"    = @(31.5, 5.0)   # the dark: chaos behind, the tower crumbling
        "gif_mandala" = @(37.2, 6.0)   # the last barriers break, the chaos settles into gold
        "gif_whale"   = @(46.0, 5.0)   # something awakens
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
