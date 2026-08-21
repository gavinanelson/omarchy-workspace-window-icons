# Changelog

All notable changes to this project are documented here.

## 1.2.0 - 2026-08-21

- Use Omarchy-installed favicons for web-app windows instead of their browser icon.
- Match Chromium-family `--app` windows by URL host and installed PWAs by app ID.
- Give Quickshell plugin windows distinct icons despite their shared process and class.
- Re-resolve identity metadata on compositor events so late title/class updates are reflected.
- Reject stale process and icon lookup results when a delegate is reused for a
  newly opened window.
- Resolve Steam and Proton games by window AppID or process environment, with
  Steam's local icon cache as a desktop-shortcut-independent fallback.
- Match wrapped commands used by Flatpak, terminal launchers, AppImages, Wine,
  and game launchers, with exact launcher-name matching as the final fallback.
- Keep matching local and generic with no site-specific rules or runtime network calls.

## 1.1.0 - 2026-08-20

- Support top, bottom, left, and right Omarchy bar orientations.
- Scale icons safely on thin bars and HiDPI displays.
- Harden geometry ordering for negative, missing, and non-numeric coordinates.
- Use Hyprland IPC addresses as a fallback for both focusing and closing windows.
- Add portable geometry-ordering tests independent of local applications.

## 1.0.0 - 2026-08-20

- Show every window in the focused Hyprland workspace.
- Sort tiled windows by compositor geometry so the bar follows scrolling-layout order.
- Place floating windows after tiled windows.
- Highlight the focused window with a rounded, theme-aware raised surface.
- Resolve application icons from Freedesktop desktop entries, `StartupWMClass`, and process executables.
- Support click-to-focus, middle-click-to-close, tooltips, and appearance settings.
