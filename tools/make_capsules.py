"""Store capsules for Steam and itch (docs/capsulas.md), from the key art the game renders itself.

Needs Builds/capsule/art_land.png and art_port.png (tools/capsule_art.tscn, see docs/capsulas.md).
Writes Builds/capsule/steam/, Builds/capsule/itch/ and Builds/capsule/presskit/ (clean art, the
logo on transparent, and layered PSDs: art, glow, title, tagline).

    python tools/make_capsules.py
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from psd_tools import PSDImage
from psd_tools.api.layers import PixelLayer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "Builds", "capsule")
FONT = os.path.join(ROOT, "fonts", "CormorantGaramond.ttf")
FONT_IT = os.path.join(ROOT, "fonts", "CormorantGaramond-Italic.ttf")
INK = (59, 56, 53)
PAPER = (235, 230, 222)
TITLE = "just tap"
TAGLINE = "if you had a bad day…"


def cover(img, w, h, fx=0.5, fy=0.5):
    """Scale and crop img to w x h, keeping the point (fx, fy) of the source as central as possible."""
    s = max(w / img.width, h / img.height)
    big = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x = min(max(0, round(fx * big.width - w / 2)), big.width - w)
    y = min(max(0, round(fy * big.height - h / 2)), big.height - h)
    return big.crop((x, y, x + w, y + h))


def text_layer(size, text, font_path, px, center, colour):
    """Text on a transparent canvas of the capsule's size, centred on center."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    font = ImageFont.truetype(font_path, px)
    d = ImageDraw.Draw(layer)
    l, t, r, b = d.textbbox((0, 0), text, font=font)
    d.text((center[0] - (l + r) / 2, center[1] - (t + b) / 2), text, font=font, fill=colour + (255,))
    return layer


def logo_layers(size, cx, cy, title_px, tagline=True, wash=True, halo_alpha=0.92):
    """[glow, title, tagline] for a logo centred on (cx, cy). The glow is paper: a halo hugging the
    letters, and (wash) a broad soft cloud that calms the art behind the logo."""
    title = text_layer(size, TITLE, FONT, title_px, (cx, cy - (title_px * 0.18 if tagline else 0)), INK)
    tag_px = max(10, round(title_px * 0.3))
    tag = text_layer(size, TAGLINE, FONT_IT, tag_px, (cx, cy + title_px * 0.48), INK) if tagline else None
    mask = title.getchannel("A")
    if tag:
        mask = ImageChops.lighter(mask, tag.getchannel("A"))
    grow = 0.09 if wash else 0.03  # the transparent logo only needs a whisper of paper around it
    halo = mask.filter(ImageFilter.MaxFilter(_odd(title_px * grow))).filter(ImageFilter.GaussianBlur(title_px * 0.12))
    halo = halo.point(lambda v: min(255, int(v * 2.2)))
    if wash:
        bbox = mask.getbbox() or (0, 0, 1, 1)
        cloud = Image.new("L", size, 0)
        pad_x, pad_y = title_px * 0.55, title_px * 0.45
        ImageDraw.Draw(cloud).ellipse((bbox[0] - pad_x, bbox[1] - pad_y, bbox[2] + pad_x, bbox[3] + pad_y), fill=200)
        cloud = cloud.filter(ImageFilter.GaussianBlur(title_px * 0.45))
        halo = ImageChops.lighter(halo, cloud)
    glow = Image.new("RGBA", size, PAPER + (0,))
    glow.putalpha(halo.point(lambda v: int(v * halo_alpha)))
    if tag:
        # the tagline is quieter than the title
        tag.putalpha(tag.getchannel("A").point(lambda v: int(v * 0.8)))
    return [glow, title, tag]


def _odd(v):
    v = max(3, int(v))
    return v if v % 2 else v + 1


def flatten(layers):
    out = layers[0].convert("RGBA")
    for l in layers[1:]:
        if l is not None:
            out = Image.alpha_composite(out, l)
    return out


def save_psd(path, art, logo):
    psd = PSDImage.new("RGB", art.size)
    for name, img in [("art", art.convert("RGBA")), ("glow", logo[0]), ("title", logo[1]), ("tagline", logo[2])]:
        if img is not None:
            psd.append(PixelLayer.frompil(img, psd, name))
    psd.save(path)


def capsule(name, art, size, focal, logo_at=None, title_frac=0.0, tagline=True, folder="steam", psd=False):
    """One capsule: art cover-cropped to size around focal, logo centred at logo_at (fractions)."""
    bg = cover(art, *size, *focal).convert("RGBA")
    layers = [bg]
    logo = None
    if logo_at:
        px = round(size[1] * title_frac)
        logo = logo_layers(size, size[0] * logo_at[0], size[1] * logo_at[1], px, tagline)
        layers += logo
    out_dir = os.path.join(SRC, folder)
    os.makedirs(out_dir, exist_ok=True)
    flatten(layers).convert("RGB").save(os.path.join(out_dir, name + ".png"))
    if psd and logo:
        save_psd(os.path.join(SRC, "presskit", name + ".psd"), bg, logo)
    print(f"{folder}/{name}.png  {size[0]}x{size[1]}")


def main():
    land = Image.open(os.path.join(SRC, "art_land.png")).convert("RGB")
    port = Image.open(os.path.join(SRC, "art_port.png")).convert("RGB")
    os.makedirs(os.path.join(SRC, "presskit"), exist_ok=True)

    # Landscape: the coloured column on the right, the logo in the empty paper on the left.
    capsule("header_capsule", land, (920, 430), (0.5, 0.45), (0.27, 0.5), 0.27)
    capsule("small_capsule", land, (462, 174), (0.62, 0.42), (0.31, 0.48), 0.4, tagline=False)
    capsule("main_capsule", land, (1232, 706), (0.5, 0.5), (0.26, 0.5), 0.2, psd=True)
    capsule("library_header", land, (920, 430), (0.5, 0.45), (0.27, 0.5), 0.27)
    capsule("library_hero", land, (3840, 1240), (0.5, 0.33))  # no text: Steam puts the logo on top
    # Portrait: sky on top for the logo, the bird below it, the city underneath.
    capsule("vertical_capsule", port, (748, 896), (0.5, 0.38), (0.5, 0.13), 0.13)
    capsule("library_capsule", port, (600, 900), (0.5, 0.5), (0.5, 0.12), 0.12, psd=True)
    # itch cover: the top of the portrait art (logo, bird and the first structures).
    capsule("cover", port, (630, 500), (0.5, 0.28), (0.5, 0.2), 0.2, folder="itch", psd=True)

    # Page background: the art faded into the paper, no text.
    bg = cover(land, 1438, 810, 0.5, 0.5)
    bg = Image.blend(bg, Image.new("RGB", bg.size, PAPER), 0.6)
    bg.save(os.path.join(SRC, "steam", "page_background.png"))
    print("steam/page_background.png  1438x810")

    # Library logo: transparent, title and tagline with only a soft halo (no cloud).
    size = (1280, 720)
    logo = logo_layers(size, 640, 340, 300, tagline=True, wash=False, halo_alpha=0.55)
    flatten([Image.new("RGBA", size, (0, 0, 0, 0))] + logo).save(os.path.join(SRC, "steam", "library_logo.png"))
    flatten([Image.new("RGBA", size, (0, 0, 0, 0))] + logo).save(os.path.join(SRC, "presskit", "logo.png"))
    print("steam/library_logo.png  1280x720 (transparent)")

    # Press kit: the clean art.
    land.save(os.path.join(SRC, "presskit", "key_art_landscape.png"))
    port.save(os.path.join(SRC, "presskit", "key_art_portrait.png"))
    print("presskit/: key art, logo, PSDs")


if __name__ == "__main__":
    main()
