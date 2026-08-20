#!/usr/bin/env bash
set -euo pipefail

plugin_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${plugin_root}/manifest.json"

jq -e '
  .schemaVersion == 1
  and .id == "gavinanelson.workspace-window-icons"
  and .version == "1.1.0"
  and (.kinds | index("bar-widget") != null)
  and .entryPoints.barWidget == "BarWidget.qml"
' "${manifest}" >/dev/null

grep -Fq 'moduleName: "gavinanelson.workspace-window-icons"' "${plugin_root}/BarWidget.qml"

node - "${plugin_root}/AppIconModel.js" <<'NODE'
const model = require(process.argv[2])
const entries = [
  { id: "org.gnome.Nautilus", startupClass: "org.gnome.Nautilus", name: "Files", command: ["nautilus"] },
  { id: "firefox", startupClass: "firefox", name: "Firefox", command: ["firefox"] },
  { id: "com.example.Editor", startupClass: "ExampleEditor", name: "Example Editor", command: ["/usr/bin/example-editor"] }
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
NODE

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
NODE

grep -Fq 'columns: root.vertical ? 1' "${plugin_root}/BarWidget.qml"
grep -Fq 'Layout.preferredHeight: root.vertical' "${plugin_root}/BarWidget.qml"

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "${plugin_root}"
fi

printf 'Workspace Window Icons checks passed.\n'
