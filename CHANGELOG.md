# Changelog

All notable changes to this project are documented here.

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
