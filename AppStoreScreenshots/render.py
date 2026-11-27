"""Render concept C ("Enter the bill, pick the tip, split it fairly, and save it.") as App Store PNGs.

usage: python3 render.py <device> <captures_dir> <out_dir>
device: iphone | ipad | duo-outer | duo-inner
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
GROUND = (234, 244, 236)
INK = (27, 107, 58)
SUB = (63, 81, 70)
HEAD = "/Library/Fonts/SF-Pro-Rounded-Bold.otf"
BODY = "/Library/Fonts/SF-Pro-Rounded-Semibold.otf"

# panel size, headline px, device top, device screen width, bezel px, screen corner radius
SPECS = {
    "iphone":    dict(size=(1320, 2868), head=136, top=470, screen_w=1060, bezel=None),
    "ipad":      dict(size=(2064, 2752), head=124, top=520, screen_w=1640, bezel=44, radius=70),
    "duo-outer": dict(size=(1398, 2034), head=110, top=330, screen_w=1060, bezel=36, radius=110),
    "duo-inner": dict(size=(2007, 2853), head=124, top=520, screen_w=1600, bezel=44, radius=80),
}

IPHONE_STORY = [
    ("Enter the bill,", "01-enter-the-bill.png"),
    ("pick the tip,", "02-pick-the-tip.png"),
    ("split it fairly,", "03-split-it-fairly.png"),
    ("and save it.", "04-save-it.png"),
]
# Big screens show the whole calculator at once, so "pick" and "split" are one shot.
WIDE_STORY = [
    ("Enter the bill,", "01-enter-the-bill.png"),
    ("pick the tip and split it,", "03-split-it-fairly.png"),
    ("and save it.", "04-save-it.png"),
]


def device_image(spec, capture):
    """Return an RGBA device image (bezel + screen) scaled so the screen is screen_w wide."""
    if spec["bezel"] is None:
        bezel = Image.open(os.path.join(S, "iphone-bezel.png")).convert("RGBA")
        phone = Image.new("RGBA", bezel.size, (0, 0, 0, 0))
        phone.paste(capture.convert("RGBA").resize((1320, 2868)), (75, 66))
        phone.alpha_composite(bezel)
        k = spec["screen_w"] / 1320
        return phone.resize((round(bezel.width * k), round(bezel.height * k)), Image.LANCZOS)

    k = spec["screen_w"] / capture.width
    sw, sh = spec["screen_w"], round(capture.height * k)
    b, r = spec["bezel"], spec["radius"]
    w, h = sw + 2 * b, sh + 2 * b
    dev = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(dev)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=r + b, fill=(18, 18, 18, 255))
    d.rounded_rectangle((3, 3, w - 4, h - 4), radius=r + b - 3, outline=(70, 70, 70, 255), width=3)
    screen = capture.convert("RGBA").resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=r, fill=255)
    dev.paste(screen, (b, b), mask)
    return dev


def shadow(img, blur=40, alpha=70):
    from PIL import ImageFilter
    a = img.split()[-1].point(lambda v: alpha if v > 0 else 0)
    sh = Image.new("RGBA", img.size, (20, 48, 30, 0))
    sh.putalpha(a)
    pad = blur * 3
    big = Image.new("RGBA", (img.width + 2 * pad, img.height + 2 * pad), (0, 0, 0, 0))
    big.paste(sh, (pad, pad))
    return big.filter(ImageFilter.GaussianBlur(blur)), pad


def dotted_path(strip, panel_h):
    """One wavy dotted line running across every panel, so the set reads as one strip."""
    d = ImageDraw.Draw(strip)
    W = strip.width
    base, amp = panel_h * 0.88, panel_h * 0.035
    step, rad = panel_h * 0.012, panel_h * 0.0035
    x = -step
    while x < W + step:
        y = base + amp * math.sin(x / (panel_h * 0.22))
        d.ellipse((x - rad, y - rad, x + rad, y + rad), fill=INK)
        x += step


def lock_icon(d, cx, cy, s):
    lw = max(6, s // 14)
    d.rounded_rectangle((cx - s * 0.42, cy - s * 0.05, cx + s * 0.42, cy + s * 0.62), radius=s * 0.12, outline=INK, width=lw)
    d.arc((cx - s * 0.27, cy - s * 0.55, cx + s * 0.27, cy - s * 0.0), 180, 360, fill=INK, width=lw)
    d.line((cx - s * 0.27, cy - s * 0.28, cx - s * 0.27, cy - s * 0.05), fill=INK, width=lw)
    d.line((cx + s * 0.27, cy - s * 0.28, cx + s * 0.27, cy - s * 0.05), fill=INK, width=lw)
    d.ellipse((cx - s * 0.07, cy + s * 0.2, cx + s * 0.07, cy + s * 0.34), fill=INK)


def fit_font(text, path, size, max_w):
    f = ImageFont.truetype(path, size)
    while f.getlength(text) > max_w and size > 40:
        size -= 4
        f = ImageFont.truetype(path, size)
    return f


def render(device, cap_dir, out_dir):
    spec = SPECS[device]
    pw, ph = spec["size"]
    story = IPHONE_STORY if device in ("iphone", "duo-outer") else WIDE_STORY
    n = len(story) + 1
    strip = Image.new("RGBA", (pw * n, ph), GROUND + (255,))
    dotted_path(strip, ph)
    d = ImageDraw.Draw(strip)

    for i, (headline, cap) in enumerate(story):
        x0 = i * pw
        f = fit_font(headline, HEAD, spec["head"], pw * 0.9)
        tw = f.getlength(headline)
        d.text((x0 + (pw - tw) / 2, spec["head"] * 1.25), headline, font=f, fill=INK)
        dev = device_image(spec, Image.open(os.path.join(cap_dir, cap)))
        sh, pad = shadow(dev)
        dx = x0 + (pw - dev.width) // 2
        strip.paste(sh, (dx - pad, spec["top"] + 30 - pad), sh)
        strip.paste(dev, (dx, spec["top"]), dev)

    # Closing panel: the privacy promise, no phone.
    x0 = len(story) * pw
    lock_icon(d, x0 + pw / 2, ph * 0.36, int(pw * 0.2))
    lines = [("No account.", HEAD, spec["head"]), ("Stays on", HEAD, spec["head"]),
             ("your " + ("iPad." if device == "ipad" else "iPhone."), HEAD, spec["head"])]
    y = ph * 0.48
    for text, path, size in lines:
        f = ImageFont.truetype(path, size)
        d.text((x0 + (pw - f.getlength(text)) / 2, y), text, font=f, fill=INK)
        y += size * 1.15

    os.makedirs(out_dir, exist_ok=True)
    for i in range(n):
        tile = strip.crop((i * pw, 0, (i + 1) * pw, ph)).convert("RGB")
        tile.save(os.path.join(out_dir, f"{device}-{i + 1}.png"))
    prev = strip.convert("RGB").resize((strip.width * 600 // ph, 600), Image.LANCZOS)
    prev.save(os.path.join(out_dir, f"{device}-strip-preview.png"))


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2], sys.argv[3])
