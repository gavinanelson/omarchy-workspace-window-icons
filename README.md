# Workspace Window Icons for Omarchy

A native Omarchy/Quickshell task strip for Hyprland scrolling workspaces. It
shows every window in the focused workspace as an application icon, including
windows outside the visible scrolling viewport.

![Workspace Window Icons in the Omarchy bar](preview.png)

## Features

- Shows only windows from the focused workspace.
- Follows the compositor's left-to-right window geometry rather than focus history.
- Keeps off-screen scrolling-layout windows visible in the bar.
- Places tiled windows first and floating windows afterward.
- Uses clean, full-opacity application icons with no idle tiles or underlines.
- Marks the focused window with a rounded, theme-aware raised surface.
- Left-clicks focus windows, middle-clicks close them, and tooltips show titles.
- Resolves icons for native apps, Electron apps, and Chromium web apps.
- Adapts to top, bottom, left, and right bars, including scaled displays.

## Install

```bash
omarchy plugin add https://github.com/gavinanelson/omarchy-workspace-window-icons --enable
```

That's it. Omarchy handles validation, enabling, and bar placement.

## Appearance settings

Right-click any window icon to adjust:

- icon saturation;
- icon size;
- unfocused icon opacity;
- spacing between icons.

The defaults use original icon colors at full opacity. Unfocused icons have no
background decoration; only the focused window receives a selection surface.

## Requirements

- Omarchy with its Quickshell-based shell.
- Hyprland.
- Standard Freedesktop desktop entries for application icon matching.

There are no extra packages, daemons, polling scripts, or network calls. Window
state comes from Quickshell's Hyprland integration. Executable lookup reads only
`/proc/<pid>/exe` to improve desktop-entry matching.

The widget has no application-specific class list or monitor coordinates. It
uses each system's Freedesktop desktop entries, focused Hyprland workspace, and
live compositor geometry, so it works with custom themes, multiple monitors,
standard Hyprland layouts, and scrolling layouts.

## Remove

```bash
omarchy plugin remove
```

Choose **Workspace Window Icons** from the list.

## Development

From the repository root, run:

```bash
omarchy plugin validate .
./tests/test_plugin.sh
```

## Attribution

Icon matching and the initial bar-widget structure were adapted from Carmine
Paolino's MIT-licensed
[crmne Active Window](https://github.com/crmne/omarchy-active-window). The
workspace model, geometry ordering, multi-window interaction, focused-state
design, settings, and packaging were developed for this plugin.

## License

MIT. See [LICENSE](LICENSE).
