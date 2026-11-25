# TipSavvy App Store Screenshot Plan

Direction: receipt panorama. Four shots whose headlines read as one sentence ("Enter the bill, pick the tip, split it fairly, and save it.") on a receipt tape that runs across all of them.

## Workflow

1. Capture raw screens (UI tests launch with `-app-store-screenshot <mode>` for exact values):
   - `Scripts/capture-app-store-screenshots.sh iphone` (also used for the 6.3" size)
   - `Scripts/capture-app-store-screenshots.sh ipad`
   - Duo outer: fold the simulator closed (Device Hub), then `Scripts/capture-app-store-screenshots.sh duo-outer "TipSavvy Shots Duo"`
   - Duo inner: unfold it flat, then `Scripts/capture-app-store-screenshots.sh duo-inner "TipSavvy Shots Duo"`. The script asks the test for the inner screen (XCUIScreen.main is the outer one) and turns the captures upright.
2. Preview and edit words or background in `AppStoreScreenshots/screenshots.html` (also published as the "TipSavvy Screenshot Studio" artifact). Copy settings into its `shot-config` block.
3. `Scripts/render-app-store-screenshots.py` renders every captured size with headless Chrome into `AppStoreScreenshots/final/<device>/` as RGB PNGs at Apple's exact sizes.

## Sizes

| Device | Pixels | Raw source |
| --- | --- | --- |
| iPhone 6.9" | 1320 × 2868 | raw/iphone |
| iPhone 6.3" | 1206 × 2622 | raw/iphone |
| iPad 13" | 2064 × 2752 | raw/ipad |
| iPhone Duo outer | 1398 × 2034 | raw/duo-outer |
| iPhone Duo inner | 2007 × 2853 | raw/duo-inner |

## Capture Notes

- Use English and a US locale (the tests set these).
- Light mode: the capture script sets it (override with APPEARANCE=dark).
- Shot 1 needs the on-screen keypad. Xcode 27 has no Simulator.app toggle: show the on-screen keyboard from Device Hub (or the Claude simulator tool) while the device is booted, then capture.
- Tests run with parallel testing off, so they use the simulator as you set it up (a parallel clone starts folded and in its default settings).
- Device frames: Duo outer and inner use Apple bezels from `AppStoreScreenshots/bezels/`; iPhone and iPad use drawn frames.
