"""Key art for the store capsules (docs/capsulas.md): an illustration made for the capsule, not a frame
of the game. Someone small sits on a grey day, hugging their knees; from the tip of one raised finger
(a tap, with its ring) an ink line climbs, turning to gold, up to a whale of light that swims over
them. Under the whale the world takes its colours back. Ink and paper, like the game, with watercolour
washes.

Writes Builds/capsule/art_land.png (3840x2160), art_port.png (1800x2700) and art_cover.png (2520x2000),
with room left for the logo; tools/make_capsules.py crops them and adds it.

    python tools/key_art.py [--fast]     (--fast: a quarter of the size, for trying things out)
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Builds", "capsule")
SS = 2  # line art is drawn at twice the size and scaled down (antialiasing)


def hexc(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255.0


PAPER = hexc("#ebe6de")
INK = hexc("#3b3835")
GOLD = hexc("#e2b65a")
WARM = hexc("#f4dfb2")
GREY = hexc("#a29c95")
RED = hexc("#c95a4f")
GREEN = hexc("#6c9c72")
BLUE = hexc("#4d84b3")
YELLOW = hexc("#d9a948")


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def catmull(ctrl, n=24):
    """A smooth curve through the control points."""
    p = np.asarray(ctrl, np.float64)
    p = np.vstack([p[0] * 2 - p[1], p, p[-1] * 2 - p[-2]])
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(p[-2])
    return np.array(out)


class Canvas:
    def __init__(self, w, h, seed):
        self.W, self.H = w, h
        self.rng = np.random.default_rng(seed)
        self.img = np.ones((h, w, 3), np.float32) * PAPER

    # --- noise, masks, blur ---------------------------------------------------

    def noise(self, scale, octaves=3):
        """Smooth value noise in 0..1; scale is the size of the biggest blobs in pixels."""
        acc = np.zeros((self.H, self.W), np.float32)
        amp, tot = 1.0, 0.0
        for o in range(octaves):
            sc = max(2, int(scale / (2 ** o)))
            small = (self.rng.random((self.H // sc + 3, self.W // sc + 3)) * 255).astype(np.uint8)
            big = Image.fromarray(small).resize((self.W + 2 * sc, self.H + 2 * sc), Image.BICUBIC)
            acc += np.asarray(big, np.float32)[sc:sc + self.H, sc:sc + self.W] / 255.0 * amp
            tot += amp
            amp *= 0.5
        n = acc / tot
        return (n - n.min()) / max(1e-6, n.max() - n.min())

    def mask(self):
        m = Image.new("L", (self.W * SS, self.H * SS), 0)
        return m, ImageDraw.Draw(m)

    def arr(self, m):
        return np.asarray(m.resize((self.W, self.H), Image.BOX), np.float32) / 255.0

    @staticmethod
    def blur(a, r):
        if r <= 0:
            return a
        im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
        return np.asarray(im.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0

    # --- paint ----------------------------------------------------------------

    def over(self, m, col, a=1.0):
        k = (m * a)[..., None]
        self.img = self.img * (1 - k) + col * k

    def mul(self, m, col, a=1.0):
        k = (m * a)[..., None]
        self.img = self.img * (1 - k * (1 - col))

    def screen(self, m, col, a=1.0):
        k = (m * a)[..., None]
        self.img = 1 - (1 - self.img) * (1 - col * k)

    def wash(self, m, col, a, blur, rough=0.4, edge=0.5, mode="mul"):
        """Watercolour: a soft, uneven puddle with pigment gathered at its edge."""
        mb = self.blur(m, blur)
        n = self.noise(max(16, blur * 4))
        v = mb * (1 - rough + rough * 2 * n)
        pud = smooth(0.18, 0.42, v)
        rim = np.clip(pud - self.blur(pud, max(2, blur * 0.08)), 0, 1)
        grain = self.noise(6, 2) * 0.25 + 0.85
        k = np.clip((pud * 0.75 + rim * edge * 3.0) * grain, 0, 1)
        getattr(self, mode)(k, col, a)
        return pud

    # --- line art -------------------------------------------------------------

    @staticmethod
    def stroke(dr, pts, w):
        pts = np.asarray(pts, np.float64) * SS
        w = np.broadcast_to(np.asarray(w, np.float64) * SS, (len(pts),))
        for i in range(len(pts) - 1):
            p, q = pts[i], pts[i + 1]
            d = q - p
            ln = math.hypot(*d)
            if ln < 1e-6:
                continue
            nrm = np.array([-d[1], d[0]]) / ln
            quad = [p + nrm * w[i] / 2, q + nrm * w[i + 1] / 2, q - nrm * w[i + 1] / 2, p - nrm * w[i] / 2]
            dr.polygon([tuple(v) for v in quad], fill=255)
        for p, r in zip(pts, w / 2):
            dr.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=255)

    @staticmethod
    def poly(dr, pts):
        dr.polygon([tuple(v) for v in np.asarray(pts) * SS], fill=255)

    def wobble(self, pts, amp):
        """Hand-drawn: nudge a line sideways, gently, along its length."""
        pts = np.asarray(pts, np.float64)
        t = np.linspace(0, 1, len(pts))
        ph = self.rng.random(3) * 6.28
        off = (np.sin(t * 7 + ph[0]) * 0.5 + np.sin(t * 17 + ph[1]) * 0.3 + np.sin(t * 41 + ph[2]) * 0.2) * amp
        d = np.gradient(pts, axis=0)
        nrm = np.stack([-d[:, 1], d[:, 0]], 1)
        nrm /= np.maximum(1e-6, np.linalg.norm(nrm, axis=1))[:, None]
        return pts + nrm * off[:, None]


# --- the whale -----------------------------------------------------------------

def _spine(u):
    """The body's middle line: a soft arch, then the tail curving up."""
    return -0.04 * np.sin(np.pi * np.minimum(u, 0.6) / 1.2) - 0.15 * smooth(0.5, 1.0, u) ** 1.6


def _thick(u):
    return (0.125 * np.sqrt(np.minimum(u / 0.2, 1.0)) * (1 - smooth(0.28, 0.9, u)) ** 1.25
            + 0.016 * smooth(0.3, 0.9, u))


def _edges(u):
    """Back and belly, offset along the curve's normal (the tail bends up)."""
    p = np.stack([u, _spine(u)], 1)
    d = np.gradient(p, axis=0)
    up = np.stack([d[:, 1], -d[:, 0]], 1)
    up /= np.linalg.norm(up, axis=1)[:, None]
    th = _thick(u)[:, None]
    return p + up * th * 0.8, p - up * th * 1.12, p, up


def whale_parts():
    """The whale in its own units: snout at x = 0, length about 1, facing left, y down. A humpback's
    tail: it curves up at the end and the flukes spread sideways, not up and down like a fish's."""
    u = np.linspace(0.0, 0.9, 140)
    top, bot, mid, up = _edges(u)
    t, n = mid[-1], up[-1]          # the end of the tail and the direction it points
    side = np.array([n[1], -n[0]])  # across the tail, towards the belly side
    span = 0.15
    left = catmull([top[-1], t - side * span * 0.5, t - side * span + n * 0.05,
                    t - side * span * 0.6 + n * 0.085, t + n * 0.06], 12)
    right = catmull([t + n * 0.06, t + side * span * 0.6 + n * 0.09, t + side * span * 1.05 + n * 0.06,
                     t + side * span * 0.5, bot[-1]], 12)
    outline = np.vstack([top, left[1:], right[1:], bot[::-1][1:]])

    def b(x):
        return float(_spine(x) + _thick(x) * 1.12)

    fin = catmull([(0.22, b(0.22) - 0.01), (0.29, b(0.27) + 0.07), (0.37, b(0.3) + 0.15), (0.41, b(0.3) + 0.17),
                   (0.39, b(0.32) + 0.12), (0.34, b(0.34) + 0.03), (0.33, b(0.33) - 0.01)], 10)
    eye = (0.125, float(_spine(0.125) + _thick(0.125) * 0.1))
    mouth = catmull([(0.012, float(_spine(0.0)) + 0.012), (0.08, float(_spine(0.08) + _thick(0.08) * 0.42)),
                     (0.19, float(_spine(0.19) + _thick(0.19) * 0.3))], 16)
    grooves = []
    for k in range(5):
        f = 0.55 + 0.11 * k
        x0, x1 = 0.05 + 0.012 * k, 0.4 - 0.02 * k
        xs = np.linspace(x0, x1, 40)
        grooves.append(np.stack([xs, _spine(xs) + _thick(xs) * 1.12 * f], 1))
    return outline, fin, eye, mouth, grooves, b


def draw_whale(c, center, length, angle_deg, light=1.0):
    outline, fin, eye, mouth, grooves, belly = whale_parts()
    th = math.radians(angle_deg)
    rot = np.array([[math.cos(th), -math.sin(th)], [math.sin(th), math.cos(th)]])

    def tf(p):
        p = np.asarray(p, np.float64).reshape(-1, 2) - np.array([0.5, 0.0])
        return p @ rot.T * length + np.asarray(center)

    body_m, dr = c.mask()
    c.poly(dr, tf(outline))
    c.poly(dr, tf(fin))
    body = c.arr(body_m)

    # its light: a wide warm halo, then a closer gold one
    c.screen(c.blur(body, length * 0.16), WARM, 0.55 * light)
    c.screen(c.blur(body, length * 0.05), GOLD, 0.35 * light)
    # the body: pale light, warmer along the belly, a highlight along the back
    c.over(body, np.clip(WARM * 1.1, 0, 1), 0.7)
    c.wash(body, GOLD, 0.3, length * 0.012, rough=0.5, edge=0.35)
    k = max(2, int(length * 0.05))
    belly_band = c.blur(np.clip(body - np.roll(body, -k, axis=0), 0, 1), length * 0.03) * body
    back_band = c.blur(np.clip(body - np.roll(body, k, axis=0), 0, 1), length * 0.02) * body
    c.mul(belly_band, GOLD, 0.45)
    c.screen(back_band, np.ones(3, np.float32), 0.45)

    # constellation inside
    pts = []
    rng = c.rng
    for x in np.linspace(0.2, 0.78, 11):
        x += rng.uniform(-0.03, 0.03)
        v = rng.uniform(-0.55, 0.8)
        pts.append((x, float(_spine(x) + _thick(x) * v)))
    pts = tf(pts)
    lines_m, ldr = c.mask()
    for i in range(len(pts) - 1):
        c.stroke(ldr, [pts[i], pts[i + 1]], length * 0.0012)
    for i in range(0, len(pts) - 3, 3):
        c.stroke(ldr, [pts[i], pts[i + 3]], length * 0.0009)
    c.over(c.arr(lines_m) * body, GOLD * 0.8, 0.7)
    dots_m, ddr = c.mask()
    for p in pts:
        r = length * rng.uniform(0.004, 0.008)
        c.stroke(ddr, [p, p], r)
    dots = c.arr(dots_m)
    c.screen(c.blur(dots, length * 0.01), GOLD, 0.9)
    c.over(dots, np.clip(GOLD * 1.15, 0, 1), 0.95)

    # ink: the outline heavier along the belly, a lighter second pass, the details
    ink_m, idr = c.mask()
    o = tf(outline)
    w = length * (0.0028 + 0.0022 * (np.linspace(0, 1, len(o)) > 0.5))
    c.stroke(idr, c.wobble(o, length * 0.0015), w)
    c.stroke(idr, c.wobble(tf(fin), length * 0.0012), length * 0.0028)
    c.stroke(idr, c.wobble(tf(mouth), length * 0.001), length * 0.0022)
    for g in grooves:
        c.stroke(idr, c.wobble(tf(g), length * 0.001), length * 0.0011)
    e = tf([eye])[0]
    c.stroke(idr, [e, e], length * 0.009)
    c.over(c.arr(ink_m), INK, 0.92)
    sketch_m, sdr = c.mask()
    c.stroke(sdr, c.wobble(o, length * 0.004) + length * 0.002, length * 0.0012)
    c.over(c.arr(sketch_m), INK, 0.3)
    return tf, belly


# --- the person ----------------------------------------------------------------

def draw_person(c, seat, s):
    """Seated on the ground, facing right, one arm around the knees and the other raised: a finger up,
    tapping. Returns the fingertip."""
    sx, sy = seat

    def P(x, y):
        return (sx + x * s, sy + y * s)

    m, dr = c.mask()
    # back, a little hunched
    c.stroke(dr, catmull([P(0.02, -0.07), P(-0.02, -0.3), P(0.04, -0.5), P(0.12, -0.6)], 10),
             np.linspace(0.22, 0.17, 31) * s)
    # thigh, shin, foot
    c.stroke(dr, [P(0.05, -0.09), P(0.4, -0.41)], [0.15 * s, 0.11 * s])
    c.stroke(dr, [P(0.4, -0.41), P(0.5, -0.04)], [0.11 * s, 0.08 * s])
    c.stroke(dr, [P(0.47, -0.03), P(0.6, -0.02)], 0.07 * s)
    # the arm around the knees
    c.stroke(dr, catmull([P(0.12, -0.52), P(0.27, -0.32), P(0.43, -0.33)], 8), 0.075 * s)
    # head, looking up a little
    hx, hy = P(0.19, -0.75)
    r = 0.125 * s
    dr.ellipse(((hx - r) * SS, (hy - r) * SS, (hx + r) * SS, (hy + r) * SS), fill=255)
    # the raised arm and its finger
    arm = catmull([P(0.15, -0.56), P(0.27, -0.78), P(0.33, -1.0)], 8)
    c.stroke(dr, arm, np.linspace(0.075, 0.05, len(arm)) * s)
    tip = P(0.345, -1.13)
    c.stroke(dr, [P(0.33, -1.0), tip], [0.03 * s, 0.022 * s])
    body = c.arr(m)
    c.over(body, INK, 0.93)

    # a red scarf, the only warm thing down here, its end lifted by the wind
    sm, sdr = c.mask()
    c.stroke(sdr, [P(0.08, -0.6), P(0.22, -0.62)], 0.07 * s)
    tail = catmull([P(0.1, -0.6), P(-0.06, -0.57), P(-0.2, -0.63), P(-0.33, -0.58)], 8)
    c.stroke(sdr, tail, np.linspace(0.065, 0.03, len(tail)) * s)
    c.over(c.arr(sm), RED, 0.95)

    # the tap: a ring opening at the fingertip
    rm, rdr = c.mask()
    for rr, w in ((0.07, 0.012), (0.13, 0.008)):
        pts = [(tip[0] + math.cos(a) * rr * s, tip[1] + math.sin(a) * rr * s) for a in np.linspace(0, 6.3, 60)]
        c.stroke(rdr, pts, w * s)
    ring = c.arr(rm)
    c.screen(c.blur(ring, s * 0.03), GOLD, 0.8)
    c.over(ring, GOLD * 0.85, 0.85)
    return tip


# --- the line, the ground, the sky ----------------------------------------------

def draw_line(c, a, b, s):
    """From the fingertip up to the whale: ink at the bottom, gold at the top, notes rising along it."""
    a, b = np.asarray(a, np.float64), np.asarray(b, np.float64)
    d = b - a
    nrm = np.array([-d[1], d[0]]) / np.linalg.norm(d)
    ctrl = [a + d * t + nrm * np.linalg.norm(d) * k for t, k in
            ((0, 0), (0.22, 0.035), (0.48, -0.03), (0.74, 0.025), (1, 0))]
    pts = c.wobble(catmull(ctrl, 30), s * 0.004)
    n = len(pts)
    for i0 in range(0, n - 1, 6):
        seg = pts[i0:i0 + 7]
        t = i0 / n
        m, dr = c.mask()
        c.stroke(dr, seg, s * (0.016 + 0.01 * t))
        col = INK * (1 - smooth(0.25, 0.85, t)) + GOLD * 0.85 * smooth(0.25, 0.85, t)
        c.over(c.arr(m), col, 0.95)
    glow_m, gdr = c.mask()
    c.stroke(gdr, pts[n // 3:], s * 0.03)
    c.screen(c.blur(c.arr(glow_m), s * 0.06), GOLD, 0.5)
    # notes
    nm, ndr = c.mask()
    for t in (0.3, 0.42, 0.55, 0.66, 0.78, 0.88):
        p = pts[int(t * (n - 1))] + nrm * s * c.rng.uniform(-0.25, 0.25)
        c.stroke(ndr, [p, p], s * c.rng.uniform(0.025, 0.045))
    notes = c.arr(nm)
    c.screen(c.blur(notes, s * 0.05), GOLD, 0.9)
    c.over(notes, np.clip(GOLD * 1.1, 0, 1), 0.9)
    # where it touches the whale, a small burst of light
    bm, bdr = c.mask()
    c.stroke(bdr, [b, b], s * 0.08)
    c.screen(c.blur(c.arr(bm), s * 0.12), WARM, 1.0)


def draw_ground(c, y, x_light, s):
    """The horizon, drawn by hand, and the whale's light pooling warm on the ground under it."""
    W = c.W
    pm, pdr = c.mask()
    r = W * 0.3
    pdr.ellipse(((x_light - r) * SS, (y - r * 0.12) * SS, (x_light + r) * SS, (y + r * 0.12) * SS), fill=255)
    soft = c.blur(c.arr(pm), r * 0.18)
    c.mul(soft, GOLD, 0.22)
    c.screen(soft, WARM, 0.3)
    m, dr = c.mask()
    xs = np.linspace(-0.02 * W, 1.02 * W, 200)
    ys = y + np.sin(xs / W * 9) * s * 0.02
    c.stroke(dr, c.wobble(np.stack([xs, ys], 1), s * 0.01), s * 0.018)
    c.over(c.arr(m), INK, 0.75)


def draw_grey(c, centre, radii, s):
    """The grey day: a cold wash low on the paper, with a little rain in it."""
    m, dr = c.mask()
    cx, cy = centre
    rx, ry = radii
    dr.ellipse(((cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS), fill=255)
    pud = c.wash(c.arr(m), GREY, 0.55, max(rx, ry) * 0.35, rough=0.55, edge=0.4)
    rm, rdr = c.mask()
    for _ in range(int(160 * c.W * c.H / (3840 * 2160))):
        x = c.rng.uniform(cx - rx, cx + rx)
        y = c.rng.uniform(cy - ry, cy + ry)
        ln = s * c.rng.uniform(0.15, 0.3)
        c.stroke(rdr, [(x, y), (x - ln * 0.25, y + ln)], s * 0.008)
    c.over(c.arr(rm) * pud, GREY * 0.8, 0.45)


def draw_stars(c, n, box, avoid, s):
    m, dr = c.mask()
    gm, gdr = c.mask()
    x0, y0, x1, y1 = box
    placed = 0
    while placed < n:
        x, y = c.rng.uniform(x0, x1), c.rng.uniform(y0, y1)
        if any(ax0 < x < ax1 and ay0 < y < ay1 for ax0, ay0, ax1, ay1 in avoid):
            continue
        r = s * c.rng.uniform(0.04, 0.1)
        if c.rng.random() < 0.35:
            c.stroke(gdr, [(x - r, y), (x + r, y)], s * 0.012)
            c.stroke(gdr, [(x, y - r * 1.3), (x, y + r * 1.3)], s * 0.012)
        else:
            c.stroke(dr, [(x, y), (x, y)], s * c.rng.uniform(0.012, 0.025))
        placed += 1
    gold = c.arr(gm)
    c.screen(c.blur(gold, s * 0.05), GOLD, 0.6)
    c.over(gold, GOLD * 0.9, 0.85)
    c.over(c.arr(m), INK, 0.5)


def paper(c):
    fine = c.noise(3, 2)
    mottle = c.noise(c.W * 0.15, 3)
    k = 1 - 0.035 * (fine - 0.5) - 0.03 * (mottle - 0.5)
    c.img *= k[..., None]


def vignette(c):
    yy, xx = np.mgrid[0:c.H, 0:c.W].astype(np.float32)
    d = np.sqrt(((xx - c.W / 2) / (c.W / 2)) ** 2 + ((yy - c.H / 2) / (c.H / 2)) ** 2)
    c.mul(smooth(0.75, 1.45, d), hexc("#6e645a"), 0.35)


# --- layouts ----------------------------------------------------------------------

def scene(w, h, seed, L):
    c = Canvas(w, h, seed)
    s = L["person_s"] * h
    paper(c)
    wc = (L["whale"][0] * w, L["whale"][1] * h)
    # the warm light from the whale, over the whole sky around it
    lm, ldr = c.mask()
    r = L["whale_len"] * w * 0.5
    ldr.ellipse(((wc[0] - r) * SS, (wc[1] - r * 0.7) * SS, (wc[0] + r) * SS, (wc[1] + r * 0.7) * SS), fill=255)
    c.screen(c.blur(c.arr(lm), r * 0.6), WARM, 0.6)
    gx, gy, grx, gry = L["grey"]
    draw_grey(c, (gx * w, gy * h), (grx * w, gry * h), s)
    seat = (L["person"][0] * w, L["person"][1] * h)
    draw_stars(c, L["stars"], (0, 0, w, L["ground"] * h - s * 1.6),
               [tuple(v * (w if i % 2 == 0 else h) for i, v in enumerate(a)) for a in L["avoid"]], s)
    draw_ground(c, L["ground"] * h, seat[0] + s * 0.8, s)
    tf, belly = draw_whale(c, wc, L["whale_len"] * w, L["whale_angle"])
    tip = draw_person(c, seat, s)
    target = tf([(0.47, belly(0.47) - 0.01)])[0]
    draw_line(c, tip, target, s)
    vignette(c)
    return Image.fromarray((np.clip(c.img, 0, 1) * 255).astype(np.uint8))


LAYOUTS = {
    # wide: the logo in the left half, the whale up on the right, the person below it
    "land": dict(size=(3840, 2160), whale=(0.68, 0.34), whale_len=0.47, whale_angle=-7, person=(0.52, 0.82),
                 person_s=0.13, ground=0.82, grey=(0.32, 0.86, 0.45, 0.22), stars=46,
                 avoid=[(0.04, 0.22, 0.44, 0.62)]),
    # tall: the logo on top, the whale across the middle, the person at the bottom
    "port": dict(size=(1800, 2700), whale=(0.52, 0.47), whale_len=0.95, whale_angle=-9, person=(0.36, 0.86),
                 person_s=0.09, ground=0.86, grey=(0.4, 0.9, 0.6, 0.12), stars=40,
                 avoid=[(0.08, 0.04, 0.92, 0.22)]),
    # itch's cover (630x500): the logo on top, everything else below it
    "cover": dict(size=(2520, 2000), whale=(0.58, 0.57), whale_len=0.68, whale_angle=-8, person=(0.33, 0.89),
                  person_s=0.12, ground=0.89, grey=(0.3, 0.95, 0.45, 0.14), stars=34,
                  avoid=[(0.1, 0.04, 0.9, 0.3)]),
    # itch's page banner (960x300): the logo on the left, the whale and the person on the right
    "banner": dict(size=(1920, 600), whale=(0.77, 0.4), whale_len=0.3, whale_angle=-7, person=(0.62, 0.88),
                   person_s=0.17, ground=0.88, grey=(0.35, 0.95, 0.5, 0.25), stars=24,
                   avoid=[(0.05, 0.1, 0.5, 0.9)]),
}


def main():
    fast = "--fast" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    for name, L in LAYOUTS.items():
        w, h = L["size"]
        if fast:
            w, h = w // 4, h // 4
        img = scene(w, h, 7, L)
        path = os.path.join(OUT, f"art_{name}{'_fast' if fast else ''}.png")
        img.save(path)
        print(path, img.size)


if __name__ == "__main__":
    main()
