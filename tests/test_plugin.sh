#!/usr/bin/env bash
set -euo pipefail

plugin_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${plugin_root}/manifest.json"

jq -e '
  .schemaVersion == 1
  and .id == "gavinanelson.workspace-window-icons"
  and .version == "1.2.1"
  and (.kinds | index("bar-widget") != null)
  and .entryPoints.barWidget == "BarWidget.qml"
' "${manifest}" >/dev/null

grep -Fq 'moduleName: "gavinanelson.workspace-window-icons"' "${plugin_root}/BarWidget.qml"

node - "${plugin_root}/AppIconModel.js" <<'NODE'
const model = require(process.argv[2])
const entries = [
  { id: "org.gnome.Nautilus", startupClass: "org.gnome.Nautilus", name: "Files", command: ["nautilus"] },
  { id: "firefox", startupClass: "firefox", name: "Firefox", command: ["firefox"] },
  { id: "com.example.Editor", startupClass: "ExampleEditor", name: "Example Editor", command: ["/usr/bin/example-editor"] },
  { id: "helium", startupClass: "helium", name: "Helium", command: ["helium"] },
  { id: "social", name: "Social", command: ["omarchy-launch-webapp", "https://social.example/feed"], icon: "social" },
  { id: "installed-pwa", name: "Installed PWA", execString: "chromium --profile-directory=Default --app-id=abcdefghijklmnop", icon: "installed-pwa" },
  { id: "steam-game", name: "Example Steam Game", command: ["steam", "steam://rungameid/960090"], icon: "steam_icon_960090" },
  { id: "wrapped-terminal", name: "Wrapped Terminal", command: ["xdg-terminal-exec", "--app-id=TUI.float", "-e", "wrapped-tool"], icon: "wrapped-tool" },
  { id: "btop-plus", name: "BTOP++", command: ["xdg-terminal-exec", "--app-id=TUI.float", "-e", "btop"], icon: "btop" },
  { id: "flatpak-app", name: "Flatpak App", command: ["flatpak", "run", "com.example.FlatpakApp"], icon: "flatpak-app" },
  { id: "wine-game", name: "Example Wine Game", command: ["lutris", "lutris:rungameid/42"], icon: "wine-game" }
]

const cases = [
  ["org.gnome.Nautilus", "org.gnome.Nautilus"],
  ["firefox", "firefox"],
  ["ExampleEditor", "com.example.Editor"],
  ["example-editor", "com.example.Editor"]
]

for (const [candidate, expected] of cases) {
  const entry = model.resolve(entries, [candidate])
  if (!entry || entry.id !== expected) throw new Error(`failed to resolve ${candidate}`)
}

if (model.resolve(entries, ["com.example.Missing"]) !== null)
  throw new Error("unknown applications must use the fallback icon")

const webApp = model.resolve(entries, ["chrome-social.example__-Default", "helium"])
if (!webApp || webApp.id !== "social")
  throw new Error("web-app URL identity must override the shared browser executable")

const browser = model.resolve(entries, ["helium", "helium"])
if (!browser || browser.id !== "helium")
  throw new Error("normal browser windows must keep the browser icon")

const installedPwa = model.resolve(entries, ["crx_abcdefghijklmnop", "chromium"])
if (!installedPwa || installedPwa.id !== "installed-pwa")
  throw new Error("installed PWA app IDs must resolve to their desktop entry")

const steamGame = model.resolve(entries, ["steam_app_960090"])
if (!steamGame || steamGame.id !== "steam-game")
  throw new Error("Steam windows must resolve through their AppID")

const steamFallback = model.resolveWindow([], {}, { appClass: "steam_app_960090" })
if (steamFallback.iconNames[0] !== "steam_icon_960090")
  throw new Error("Steam AppIDs must provide the standard Steam icon name without a shortcut entry")

const steamFromEnvironment = model.resolveWindow(entries, {}, {
  appClass: "unhelpful-game-window", steamAppId: "960090", title: "BloonsTD6"
})
if (!steamFromEnvironment.entry || steamFromEnvironment.entry.id !== "steam-game")
  throw new Error("Steam process environment AppIDs must identify games with unrelated classes")

if (model.resolve(entries, ["wrapped-tool"]).id !== "wrapped-terminal")
  throw new Error("terminal and environment wrappers must expose their nested command")

if (model.resolve(entries, ["TUI.float"], ["btop"]).id !== "btop-plus")
  throw new Error("terminal windows must resolve through exact normalized titles and nested commands")

if (model.resolve(entries, ["com.example.FlatpakApp"]).id !== "flatpak-app")
  throw new Error("Flatpak application IDs must match their nested command")

if (model.resolve(entries, ["wine-window"], ["Example Wine Game"]).id !== "wine-game")
  throw new Error("exact launcher names must be the final fallback for wrapped games")

if (model.resolve(entries, [], ["Example Wine Game"]).id !== "wine-game")
  throw new Error("title fallback must still work when a client exposes no useful class")

const browserTitleCollision = model.resolveWindow(entries, {}, {
  appClass: "helium", executableName: "helium", title: "Example Wine Game"
})
if (!browserTitleCollision.entry || browserTitleCollision.entry.id !== "helium")
  throw new Error("title fallback must not override a stronger application identity")

const plugins = {
  "mail.client": {
    id: "mail.client",
    name: "Shell Mail",
    __sourceDir: "/plugins/mail.client",
    barWidget: { displayName: "Mail", aliases: ["email"] }
  },
  "shell.music": {
    id: "shell.music",
    name: "Shell Music",
    __sourceDir: "/plugins/shell.music",
    barWidget: { aliases: ["spotify"] }
  }
}

const mailPlugin = model.resolvePlugin(plugins, ["Shell Mail"], ["org.quickshell", "quickshell"])
if (!mailPlugin || mailPlugin.id !== "mail.client")
  throw new Error("Quickshell windows must resolve from their plugin title")

if (model.resolvePlugin(plugins, ["Shell Mail - Browser"], ["helium"]) !== null)
  throw new Error("non-Quickshell windows must not be relabeled as plugins")

if (model.resolvePlugin(plugins, ["player"], ["org.quickshell"]) !== null)
  throw new Error("generic launcher aliases must not identify plugin windows")

const spotifyEntry = model.resolve([
  { id: "spotify", name: "Spotify", command: ["spotify"], icon: "spotify-client" }
], model.pluginCandidates(plugins["shell.music"]))
if (!spotifyEntry || spotifyEntry.id !== "spotify")
  throw new Error("plugin aliases must resolve icons through launcher desktop entries")

const pluginIcons = model.pluginIconValues(mailPlugin)
if (!pluginIcons.includes("/plugins/mail.client/assets/mail-client.svg"))
  throw new Error("plugin icon conventions must include plugin-local assets")
NODE

test_home="$(mktemp -d)"
trap 'rm -rf -- "$test_home"' EXIT
steam_cache="$test_home/.local/share/Steam/appcache/librarycache/24680"
mkdir -p "$steam_cache"
touch "$steam_cache/0123456789abcdef0123456789abcdef01234567.jpg"
resolved_steam_icon="$(HOME="$test_home" XDG_DATA_HOME="$test_home/.local/share" \
  "${plugin_root}/scripts/steam-icon.sh" 24680)"
if [[ $resolved_steam_icon != "$steam_cache/0123456789abcdef0123456789abcdef01234567.jpg" ]]; then
  echo "Steam cache icon lookup failed" >&2
  exit 1
fi

if [[ -n $(HOME="$test_home" "${plugin_root}/scripts/steam-icon.sh" invalid) ]]; then
  echo "Steam cache lookup must reject invalid AppIDs" >&2
  exit 1
fi

node - "${plugin_root}/WorkspaceModel.js" <<'NODE'
const model = require(process.argv[2])
const window = (address, x, y, floating = false) => ({
  lastIpcObject: { address, at: [x, y], floating }
})

const ordered = model.sortedWindows([
  window("floating", -500, 0, true),
  window("right", 1800, 0),
  window("negative", -1800, 0),
  window("lower", 0, 800),
  window("upper", 0, 0),
  { lastIpcObject: { address: "missing", floating: false } }
])

const addresses = ordered.map(model.addressOf)
const expected = ["negative", "upper", "lower", "right", "missing", "floating"]
if (JSON.stringify(addresses) !== JSON.stringify(expected)) {
  throw new Error(`unexpected geometry order: ${addresses.join(", ")}`)
}

if (model.coordinate({ at: ["not-a-number", null] }, 0) !== 999999) {
  throw new Error("invalid coordinates must sort last")
}

const clients = [
  { address: "ws2", workspace: { id: 2 }, at: [0, 0], floating: false },
  { address: "right", workspace: { id: 1 }, at: [900, 0], floating: false },
  { address: "left", workspace: { id: 1 }, at: [0, 0], floating: false }
]
const compositorOrder = model.orderedAddresses(clients, 1)
if (JSON.stringify(compositorOrder) !== JSON.stringify(["left", "right"])) {
  throw new Error(`unexpected compositor snapshot order: ${compositorOrder.join(", ")}`)
}

const staleToplevels = [window("left", 900, 0), window("right", 0, 0)]
const refreshed = model.sortedWindows(staleToplevels, compositorOrder).map(model.addressOf)
if (JSON.stringify(refreshed) !== JSON.stringify(["left", "right"])) {
  throw new Error(`compositor snapshot must override stale QML geometry: ${refreshed.join(", ")}`)
}
NODE

grep -Fq 'columns: root.vertical ? 1' "${plugin_root}/BarWidget.qml"
grep -Fq 'Layout.preferredHeight: root.vertical' "${plugin_root}/BarWidget.qml"
grep -Fq 'workspace-window-icons-reordered' "${plugin_root}/BarWidget.qml"
grep -Fq 'interval: 350' "${plugin_root}/BarWidget.qml"

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "${plugin_root}"
fi

printf 'Workspace Window Icons checks passed.\n'
