# TipSavvy Release Checklist

Use this before archiving a new App Store build.

## App Store Metadata

- Subtitle: `Tip & Split Bills Fast`
- Description: mention tip calculation, split count, rounding, copy/share, saved calculations, and accessibility-friendly design.
- What's New: mention settings, rounding, saved tip management, accessibility polish, reliability, and updated app icon.
- Privacy Policy URL: `https://docs.google.com/document/d/e/2PACX-1vT5uoP653Dd3_hKw-ozR0c0YxUhKPlGNglEByGnuWDC4M7rzMwI4gIdw-mFvU94Ma3gxW5JV-XNj_KW/pub`
- Age Rating: `4+`
- Accessibility claims: VoiceOver-friendly, Larger Text-friendly, Dark Interface, Differentiate Without Color Alone, Reduced Motion, and Sufficient Contrast after manual verification.
- Encryption/export compliance: app does not use non-exempt encryption; `ITSAppUsesNonExemptEncryption` should remain `false`.

## Privacy Nutrition

- Account: not required.
- Local data: saved calculations stay on device.
- Diagnostics: Firebase Crashlytics crash data/diagnostics may be collected.
- Analytics: no product analytics configured.
- Tracking: no tracking.
- Location, contacts, payment info: not collected.

## Manual QA

- Calculator: enter a bill, change tip, change split count, choose each rounding mode, copy total/per-person, reset.
- Save flow: save a named calculation, confirm success, verify invalid bill/name behavior.
- Saved tips: search, sort, filter, clear filters, open detail, copy/share, rename, delete.
- Settings: change defaults, toggle haptics, open Privacy Policy, Contact, Rate TipSavvy, App Store review fallback, reset preferences.
- App Shortcuts: confirm TipSavvy calculator shortcut appears after install and opens the app.

## Accessibility QA

- VoiceOver: complete calculate, save, saved detail, and settings flows.
- Larger Text: verify calculator, saved tips, saved detail, and settings remain readable.
- Dark Interface: verify all main screens.
- Increased Contrast: verify glass panels, text, buttons, and destructive actions remain legible.
- Differentiate Without Color Alone: verify selected states and errors use labels/icons, not color only.
- Reduced Motion: verify animations are reduced and flows still feel stable.

## Upload Checks

- Run `Scripts/release_preflight.sh`.
- Confirm all app icons are `1024x1024` and `hasAlpha: no`.
- Confirm archive validation passes in Xcode Organizer.
- Confirm Crashlytics configuration is present.
- Confirm App Store screenshots match the current UI and copy.
