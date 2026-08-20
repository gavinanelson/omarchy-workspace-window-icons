#!/usr/bin/env bash
set -euo pipefail

plugin_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${plugin_root}/manifest.json"

jq -e '
  .schemaVersion == 1
  and .id == "gavinanelson.workspace-window-icons"
  and .version == "1.0.0"
  and (.kinds | index("bar-widget") != null)
  and .entryPoints.barWidget == "BarWidget.qml"
' "${manifest}" >/dev/null

grep -Fq 'moduleName: "gavinanelson.workspace-window-icons"' "${plugin_root}/BarWidget.qml"

node - "${plugin_root}/AppIconModel.js" <<'NODE'
const model = require(process.argv[2])
const entries = [
  { id: "t3code", startupClass: "t3code", name: "T3 Code", command: ["t3code-nightly"] },
  { id: "com.mitchellh.ghostty", startupClass: "com.mitchellh.ghostty", name: "Ghostty", command: ["ghostty"] },
  { id: "chatgpt", startupClass: "chatgpt", name: "ChatGPT", command: ["chatgpt"] }
]

for (const id of ["t3code", "com.mitchellh.ghostty", "chatgpt"]) {
  const entry = model.resolve(entries, [id])
  if (!entry || entry.id !== id) throw new Error(`failed to resolve ${id}`)
}
NODE

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "${plugin_root}"
fi

printf 'Workspace Window Icons checks passed.\n'
