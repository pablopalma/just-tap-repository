"""The trailer cut like GRIS's launch trailer (4/11/2026): no text, one piece of music
(What Breaks, Returns, from 40 s), shots dissolving into each other on its phrases, the Mother
 breaking on its climax and the title on paper in its silence at 2:00.
Record the clips into Builds/trailer/v4 first (1600x900 window, see the tools' headers):
  gameplay.avi  tools/tiktok_gameplay.tscn -- en zoom=1.25
  forks.avi     tools/orchestra_test.tscn -- 46 strong en
  madre.avi     tools/monument.tscn -- auto end en
  whale.avi     tools/demo_end_test.tscn -- en
then, from Builds/trailer/v4 (with title.ttf and font.ttf copied from fonts/):
  python ../../../tools/trailer_gris.py fc6.txt   -> prints the inputs; run ffmpeg with -/filter_complex fc6.txt
"""
import sys

B = "../../"
SRC = [
    "gameplay.avi", "forks.avi", "madre.avi", "whale.avi",                      # 0-3
    B + "trailer/espiral_zona3.mp4", B + "trailer/droste_zonas_3_4.mp4",         # 4-5
    B + "trailer/ciervo.mp4", B + "trailer/demo_cinematica_ahora.mp4",           # 6-7
    B + "songs/espiral_ritmo_ave.mp4", B + "songs/espiral_final.mp4",            # 8-9
    B + "monument/madre_kundalini_v3.mp4",                                       # 10
]
SONG_FROM = 40.0
# (song time it starts at, source, source time)
SHOTS = [
    (40.0, 2, 28.0),    # her palm takes the light: the intimate opening
    (47.0, 0, 3.0),     # the tip, the notes of light, grey
    (52.0, 4, 8.0),     # the bird over the spiral
    (55.0, 0, 8.5),     # the star, as an orchestra
    (58.0, 5, 27.0),    # the red wash, the dive inward
    (61.0, 1, 12.0),    # the braided branches
    (64.0, 6, 19.0),    # the deer of stars
    (67.0, 7, 8.0),     # the dark, the mandala
    (70.0, 8, 36.0),    # the bird of stars forming
    (72.0, 3, 9.0),     # the whale wakes
    (74.0, 3, 14.0),    # the whale swims
    (76.0, 0, 18.0),    # the red comes back
    (78.0, 10, 6.0),    # the monument at sunset
    (80.5, 2, 9.7),     # the crown: gold in the cracks, she breaks on the climax (84.7), comes back
    (96.0, 3, 15.4),    # the light comes back after the dark
    (104.0, 8, 44.0),   # the bird of stars, whole
    (112.0, 9, 8.0),    # the gold glow, filling everything
]
END = 120.0           # the drop: the title on paper, in the silence
TITLE = 8.0
T = 0.5               # dissolve

lines = []
n = len(SHOTS)
for i, (start, src, at) in enumerate(SHOTS):
    end = SHOTS[i + 1][0] if i + 1 < n else END
    d = end - start
    length = d + (T if i + 1 < n else 0.0)
    extra = ""
    if i == n - 1:
        extra = ",fade=t=out:st=%.2f:d=1.6:color=0xebe6de" % (length - 1.6)
    lines.append("[%d:v]trim=%.2f:%.2f,setpts=PTS-STARTPTS,fps=30,scale=1920:1080:flags=lanczos,setsar=1,format=yuv420p%s[s%d];"
                 % (src, at, at + length, extra, i))
acc = "s0"
off = 0.0
for i in range(1, n):
    off += SHOTS[i][0] - SHOTS[i - 1][0]
    lines.append("[%s][s%d]xfade=transition=fade:duration=%.2f:offset=%.2f[x%d];" % (acc, i, T, off, i))
    acc = "x%d" % i
lines.append("color=c=0xebe6de:s=1920x1080:r=30:d=%.1f,format=yuv420p,vignette=angle=0.55:mode=forward,"
             "drawtext=fontfile=title.ttf:text='just tap':fontsize=150:fontcolor=0x3b3835:x=(w-text_w)/2:y=h*0.40:alpha='clip((t-0.9)/1.8,0,1)',"
             "drawtext=fontfile=font.ttf:text='if you had a bad day...':fontsize=54:fontcolor=0x6b645c:x=(w-text_w)/2:y=h*0.40+190:alpha='clip((t-2.8)/1.8,0,1)',"
             "setsar=1[title];" % TITLE)
total = END - SONG_FROM + TITLE
lines.append("[%s][title]concat=n=2:v=1:a=0,fade=t=in:st=0:d=1.5,fade=t=out:st=%.2f:d=1.0:color=0xebe6de,format=yuv420p[vout];" % (acc, total - 1.0))
lines.append("[%d:a]atrim=%.2f:%.2f,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=2,afade=t=out:st=%.2f:d=3,loudnorm=I=-14:TP=-1.5:LRA=11[aout]"
             % (len(SRC), SONG_FROM, SONG_FROM + total, total - 3.0))
open(sys.argv[1], "w").write("\n".join(lines))
print(" ".join("-i \"%s\"" % s for s in SRC) + " -i \"" + B + "../audio/music/what_breaks_returns.ogg\"")
print("total %.1f s" % total)
