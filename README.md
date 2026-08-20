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

## Install

```bash
omarchy plugin add https://github.com/gavinanelson/omarchy-workspace-window-icons.git --enable --yes
omarchy bar move gavinanelson.workspace-window-icons --section left --after omarchy.workspaces
```

If you use a custom workspace widget, move this plugin after that widget's ID
instead:

```bash
omarchy bar move gavinanelson.workspace-window-icons --section left --after your.workspace-widget
```

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

## Remove

```bash
omarchy plugin remove gavinanelson.workspace-window-icons --yes
```

## Development

Install the repository at
`~/.config/omarchy/plugins/gavinanelson.workspace-window-icons`, then run:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/gavinanelson.workspace-window-icons
./tests/test_plugin.sh
omarchy restart shell
```

## Attribution

Icon matching and the initial bar-widget structure were adapted from Carmine
Paolino's MIT-licensed
[crmne Active Window](https://github.com/crmne/omarchy-active-window). The
workspace model, geometry ordering, multi-window interaction, focused-state
design, settings, and packaging were developed for this plugin.

## License

MIT. See [LICENSE](LICENSE).
