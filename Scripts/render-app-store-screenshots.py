#!/usr/bin/env python3
"""Renders the final App Store screenshots from AppStoreScreenshots/screenshots.html.

    Scripts/render-app-store-screenshots.py            # every device that has raw captures
    Scripts/render-app-store-screenshots.py iphone ipad

Layout, words and colors come from the shot-config block in screenshots.html (the same
page you preview as the artifact). Raw captures come from
Scripts/capture-app-store-screenshots.sh. Output: AppStoreScreenshots/final/<device>/*.png,
flattened to RGB (App Store Connect rejects PNGs with an alpha channel).
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: python3 -m pip install --user pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent / "AppStoreScreenshots"
PAGE = ROOT / "screenshots.html"
CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
]


def load_config():
    html = PAGE.read_text()
    match = re.search(r'<script type="application/json" id="shot-config">(.*?)</script>', html, re.S)
    if not match:
        sys.exit(f"No shot-config block found in {PAGE}")
    return json.loads(match.group(1))


def find_chrome():
    for path in CHROME_CANDIDATES:
        if pathlib.Path(path).exists():
            return path
    found = shutil.which("google-chrome") or shutil.which("chromium")
    if found:
        return found
    sys.exit("Google Chrome is needed to render. Install it, or add its path to CHROME_CANDIDATES.")


def render(chrome, device_key, device, shot_index, shot, out_dir, profile):
    out = out_dir / f"{shot['file']}.png"
    url = f"{PAGE.as_uri()}?render={device_key}&shot={shot_index}"
    subprocess.run(
        [
            chrome,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            "--allow-file-access-from-files",
            f"--user-data-dir={profile}",
            f"--window-size={device['w']},{device['h']}",
            "--virtual-time-budget=6000",
            f"--screenshot={out}",
            url,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    with Image.open(out) as img:
        if img.size != (device["w"], device["h"]):
            sys.exit(f"{out} came out {img.size[0]}x{img.size[1]}, expected {device['w']}x{device['h']}")
        img.convert("RGB").save(out, "PNG", optimize=True)
    return out


def main():
    config = load_config()
    devices = config["devices"]
    wanted = sys.argv[1:] or list(devices)
    unknown = [d for d in wanted if d not in devices]
    if unknown:
        sys.exit(f"Unknown device(s): {', '.join(unknown)}. Known: {', '.join(devices)}")

    chrome = find_chrome()
    rendered, skipped = 0, []
    with tempfile.TemporaryDirectory() as profile:
        for key in wanted:
            device = devices[key]
            raw_dir = ROOT / "raw" / device["raw"]
            missing = [s["file"] for s in config["shots"] if not (raw_dir / f"{s['file']}.png").exists()]
            if missing:
                skipped.append(f"{key} (no captures in raw/{device['raw']}: run Scripts/capture-app-store-screenshots.sh {device['raw']})")
                continue
            out_dir = ROOT / "final" / key
            out_dir.mkdir(parents=True, exist_ok=True)
            print(f"{device['label']} · {device['w']}x{device['h']}")
            for i, shot in enumerate(config["shots"]):
                out = render(chrome, key, device, i, shot, out_dir, profile)
                print(f"  {out.relative_to(ROOT.parent)}")
                rendered += 1

    for line in skipped:
        print(f"Skipped {line}")
    if not rendered:
        sys.exit("Nothing rendered.")
    print(f"Rendered {rendered} screenshots into {ROOT / 'final'}")


if __name__ == "__main__":
    main()
