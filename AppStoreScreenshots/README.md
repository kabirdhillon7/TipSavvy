# App Store screenshots

One continuous strip per device: "Enter the bill, pick the tip, split it fairly, and save it." plus a closing privacy panel.

| Device | Size | Files |
| --- | --- | --- |
| iPhone 6.9" | 1320×2868 | `output/iphone-1…5.png` |
| iPad 13" | 2064×2752 | `output/ipad-1…4.png` |
| iPhone Duo outer | 1398×2034 | `output/duo-outer-1…5.png` |
| iPhone Duo inner | 2007×2853 | `output/duo-inner-1…4.png` |

iPad and Duo inner show the whole calculator at once, so "pick the tip" and "split it" share a panel there.

## Re-shooting

1. Capture with `TipSavvyUITests/AppStoreScreenshotTests.swift`. It launches with `-app-store-screenshot calculator` ($86.40, 20%, 3 people, Person Up) or `saved`. Use simulators in light mode with the software keyboard on (`defaults write com.apple.Preferences AutomaticMinimizationEnabled -bool NO` in the simulator) and a 9:41 status bar override. Run with `-parallel-testing-enabled NO` so clones don't lose those settings.
2. The Duo inner screen can't be captured by the UI test (`XCUIScreen.main` is the outer screen). Unfold the simulator and rotate it to portrait, launch the app with the same arguments, then run `xcrun simctl io <id> screenshot --display=3`.
3. Put the PNGs in `captures/<device>/` and run `python3 render.py <iphone|ipad|duo-outer|duo-inner> captures/<device> output`.

Headlines use SF Pro Rounded from `/Library/Fonts`.
