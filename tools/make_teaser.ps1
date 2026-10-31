# A short teaser for social posts (Reddit, Bluesky), cut from the trailer: fewer, longer shots
# joined by soft crossfades, each with a short caption so it reads with the sound off.
#   Builds/trailer/just_tap_teaser.mp4         — 16:9, 1080p
#   Builds/trailer/just_tap_teaser_square.mp4  — 1:1, 1080×1080 (phones)
# Needs Builds/trailer/just_tap_trailer.mp4 (tools/make_trailer.ps1). Shot times follow docs/trailer.md.
# Usage: powershell -File tools/make_teaser.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
$src = "Builds/trailer/just_tap_trailer.mp4"
$fade = 0.6

# [start s, length s, caption, light text on dark?, square crop x]
$shots = @(
    @(5.9, 5.0, "tap, and the line climbs", $false, 420),
    @(11.45, 2.85, "grow the tree", $false, 420),
    @(18.6, 4.3, "the world draws itself, and the colour comes back", $false, 420),
    @(31.6, 4.6, "then the dark", $true, 420),
    @(41.5, 4.2, "until everything finds its place", $true, 420),
    @(46.6, 4.8, "", $true, 150),
    @(52.0, 3.7, "", $false, 420)
)

function Build($out, $square) {
    $f = ""
    $total = 0.0
    for ($i = 0; $i -lt $shots.Count; $i++) {
        $s, $d, $cap, $light, $x = $shots[$i]
        $crop = if ($square) { ",crop=1080:1080:${x}:0" } else { "" }
        $size = if ($square) { 50 } else { 58 }
        $col = if ($light) { "0xf2f0ea" } else { "0x3b3835" }
        $shadow = if ($light) { "0x000000@0.6" } else { "0xebe6de@0.9" }
        $text = ""
        if ($cap -ne "") {
            # fades in after the crossfade, out before the next one
            $alpha = "if(lt(t,0.4),0,if(lt(t,0.8),(t-0.4)/0.4,if(gt(t,$($d - 0.9)),max(0,($($d - 0.5)-t)/0.4),1)))"
            $text = ",drawtext=fontfile=fonts/CormorantGaramond-Italic.ttf:text='$cap':fontsize=${size}:fontcolor=${col}:shadowcolor=${shadow}:shadowx=0:shadowy=2:alpha='$alpha':x=(w-text_w)/2:y=h*0.1"
        }
        $f += "[0:v]trim=start=${s}:duration=${d},setpts=PTS-STARTPTS${crop}${text},fps=60,format=yuv420p[v$i];"
        $f += "[0:a]atrim=start=${s}:duration=${d},asetpts=PTS-STARTPTS[a$i];"
    }
    # chain the crossfades
    $vPrev = "v0"; $aPrev = "a0"; $total = $shots[0][1]
    for ($i = 1; $i -lt $shots.Count; $i++) {
        $off = [math]::Round($total - $fade, 3)
        $f += "[$vPrev][v$i]xfade=transition=fade:duration=${fade}:offset=${off}[vx$i];"
        $f += "[$aPrev][a$i]acrossfade=d=${fade}:c1=tri:c2=tri[ax$i];"
        $vPrev = "vx$i"; $aPrev = "ax$i"
        $total = $total + $shots[$i][1] - $fade
    }
    $f += "[$aPrev]afade=t=out:st=$([math]::Round($total - 1.0, 3)):d=1.0,loudnorm=I=-14:TP=-1.5:LRA=11[aout]"
    & $ffmpeg -v error -y -i $src -filter_complex $f -map "[$vPrev]" -map "[aout]" -c:v libx264 -preset slow -crf 20 `
        -pix_fmt yuv420p -c:a aac -b:a 160k -ar 48000 -movflags +faststart $out
}

Push-Location $root  # relative font paths keep drawtext free of drive-letter colons
try {
    Build "Builds/trailer/just_tap_teaser.mp4" $false
    Build "Builds/trailer/just_tap_teaser_square.mp4" $true
    Get-ChildItem Builds/trailer/just_tap_teaser*.mp4 | Select-Object Name, @{ n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }
} finally {
    Pop-Location
}
