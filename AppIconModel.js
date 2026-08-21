function normalized(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/\.desktop$/, "")
}

function compact(value) {
  return normalized(value).replace(/[^a-z0-9]+/g, "")
}

function finalSegment(value) {
  var parts = normalized(value).split(/[.:/_-]+/).filter(function(part) { return part.length > 0 })
  return parts.length ? parts[parts.length - 1] : ""
}

function executableName(entry) {
  if (!entry) return ""

  try {
    if (entry.command && entry.command.length) {
      var command = String(entry.command[0] || "")
      if (command) return command.slice(command.lastIndexOf("/") + 1)
    }
  } catch (e) {
  }

  var exec = String(entry.execString || "").trim()
  if (!exec) return ""
  var first = exec.split(/\s+/)[0].replace(/^['"]|['"]$/g, "")
  return first.slice(first.lastIndexOf("/") + 1)
}

function commandText(entry) {
  if (!entry) return ""

  try {
    if (entry.command && entry.command.length) {
      var parts = []
      for (var i = 0; i < entry.command.length; i++) parts.push(String(entry.command[i] || ""))
      if (parts.length) return parts.join(" ")
    }
  } catch (e) {
  }

  return String(entry.execString || "")
}

function commandTokens(entry) {
  var values = []
  var raw = []

  try {
    if (entry && entry.command && entry.command.length) {
      for (var i = 0; i < entry.command.length; i++) raw.push(String(entry.command[i] || ""))
    }
  } catch (e) {
  }

  if (!raw.length) raw = commandText(entry).match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) || []

  for (var j = 0; j < raw.length; j++) {
    var token = String(raw[j] || "").replace(/^['"]|['"]$/g, "")
    if (!token || token.charAt(0) === "-" || token.charAt(0) === "%"
        || /^[A-Za-z_][A-Za-z0-9_]*=/.test(token)
        || /^[a-z][a-z0-9+.-]*:\/\//i.test(token)) continue
    pushUnique(values, normalized(token))
    pushUnique(values, normalized(token.slice(token.lastIndexOf("/") + 1)))
  }

  return values
}

function normalizedHost(value) {
  var host = String(value || "").trim().toLowerCase()
  host = host.replace(/^www\./, "").replace(/\.$/, "")
  return host
}

function webAppUrls(entry) {
  var command = commandText(entry)
  var matches = command.match(/https?:\/\/[^\s"'<>]+/gi) || []
  var result = []

  for (var i = 0; i < matches.length; i++) {
    var url = matches[i].replace(/[),;]+$/, "")
    if (result.indexOf(url) === -1) result.push(url)
  }

  return result
}

function hostFromUrl(value) {
  var match = String(value || "").match(/^https?:\/\/([^\/?#]+)/i)
  if (!match) return ""

  var authority = match[1].replace(/^[^@]+@/, "")
  var host = authority.charAt(0) === "["
    ? authority.replace(/^\[([^\]]+)\](?::\d+)?$/, "$1")
    : authority.replace(/:\d+$/, "")
  return normalizedHost(host)
}

function appIds(entry) {
  var command = commandText(entry)
  var matcher = /--app-id(?:=|\s+)([a-z0-9_-]+)/gi
  var result = []
  var match

  while ((match = matcher.exec(command)) !== null) {
    var value = normalized(match[1])
    if (value && result.indexOf(value) === -1) result.push(value)
  }

  return result
}

function webAppIdentity(candidate) {
  var value = normalized(candidate)
  var appIdMatch = value.match(/^crx[_-]([a-z0-9_-]+)$/)
  if (appIdMatch) return { appId: appIdMatch[1], host: "" }

  var browserMatch = value.match(/^(?:chrome|chromium|brave|helium|msedge|microsoft-edge|vivaldi|opera)-(.+)$/)
  if (!browserMatch) return null

  var encoded = browserMatch[1]
    .replace(/__-(?:default|profile-\d+)$/, "")
    .replace(/-(?:default|profile-\d+)$/, "")
  var encodedAppId = encoded.match(/^crx[_-]([a-z0-9_-]+)$/)
  if (encodedAppId) return { appId: encodedAppId[1], host: "" }

  // Chromium-family --app windows begin their generated app ID with the URL
  // host. A following underscore belongs to the encoded path/profile data.
  var host = normalizedHost(encoded.split("_")[0])
  return host && host.indexOf(".") !== -1 ? { appId: "", host: host } : null
}

function webAppScore(entry, candidates) {
  var identities = candidateValues(candidates)
  var urls = webAppUrls(entry)
  var ids = appIds(entry)
  var best = -1

  for (var i = 0; i < identities.length; i++) {
    var identity = webAppIdentity(identities[i])
    if (!identity) continue

    if (identity.appId && ids.indexOf(identity.appId) !== -1) best = Math.max(best, 1320)

    if (identity.host) {
      for (var j = 0; j < urls.length; j++) {
        if (hostFromUrl(urls[j]) === identity.host) best = Math.max(best, 1300)
      }
    }
  }

  return best
}

function steamAppIds(values) {
  var candidates = candidateValues(values)
  var result = []

  for (var i = 0; i < candidates.length; i++) {
    var matcher = /(?:steam[_-]?app(?:id)?[_-]?|steam:\/\/(?:run|rungameid)\/)(\d+)/gi
    var match
    while ((match = matcher.exec(candidates[i])) !== null) pushUnique(result, match[1])
  }

  return result
}

function steamEntryAppIds(entry) {
  var command = commandText(entry)
  var result = steamAppIds([command])
  var matcher = /(?:-applaunch\s+|rungameid\/|steam:\/\/run\/)(\d+)/gi
  var match
  while ((match = matcher.exec(command)) !== null) pushUnique(result, match[1])
  return result
}

function steamScore(entry, candidates) {
  var windowIds = steamAppIds(candidates)
  var entryIds = steamEntryAppIds(entry)
  for (var i = 0; i < windowIds.length; i++)
    if (entryIds.indexOf(windowIds[i]) !== -1) return 1400
  return -1
}

function steamIconNames(candidates) {
  var ids = steamAppIds(candidates)
  var result = []
  for (var i = 0; i < ids.length; i++) pushUnique(result, "steam_icon_" + ids[i])
  return result
}

function candidateValues(candidates) {
  var result = []
  var source = Array.isArray(candidates) ? candidates : [candidates]
  for (var i = 0; i < source.length; i++) {
    var value = normalized(source[i])
    if (value && result.indexOf(value) === -1) result.push(value)
  }
  return result
}

function pushUnique(values, value) {
  var text = String(value || "").trim()
  if (text && values.indexOf(text) === -1) values.push(text)
}

function pluginTitleCandidates(manifest) {
  if (!manifest) return []

  var result = []
  pushUnique(result, manifest.id)
  pushUnique(result, manifest.name)

  var barWidget = manifest.barWidget || ({})
  pushUnique(result, barWidget.displayName)
  return result
}

function pluginCandidates(manifest) {
  if (!manifest) return []

  var result = pluginTitleCandidates(manifest)
  var barWidget = manifest.barWidget || ({})

  var aliases = Array.isArray(barWidget.aliases) ? barWidget.aliases : []
  for (var i = 0; i < aliases.length; i++) pushUnique(result, aliases[i])
  return result
}

function isQuickshellWindow(candidates) {
  var values = candidateValues(candidates)
  for (var i = 0; i < values.length; i++) {
    if (values[i] === "quickshell" || values[i] === "org.quickshell"
        || values[i].indexOf("org.quickshell.") === 0) return true
  }
  return false
}

function pluginTitleScore(manifest, titles) {
  var titleValues = candidateValues(titles)
  var names = candidateValues(pluginTitleCandidates(manifest))
  var best = -1

  for (var i = 0; i < titleValues.length; i++) {
    var title = titleValues[i]
    for (var j = 0; j < names.length; j++) {
      var name = names[j]
      if (title === name) best = Math.max(best, 1300)
      if (name.length >= 3 && (title.indexOf(name + " - ") === 0
          || title.indexOf(name + " — ") === 0
          || title.indexOf(name + " | ") === 0
          || title.indexOf(name + ": ") === 0)) best = Math.max(best, 1240)
    }
  }

  return best
}

function resolvePlugin(manifests, titles, windowCandidates) {
  if (!isQuickshellWindow(windowCandidates)) return null

  var values = manifests || ({})
  var bestManifest = null
  var bestScore = -1
  for (var id in values) {
    if (!Object.prototype.hasOwnProperty.call(values, id)) continue
    var manifest = values[id]
    var score = pluginTitleScore(manifest, titles)
    if (score > bestScore) {
      bestManifest = manifest
      bestScore = score
    }
  }

  return bestScore >= 1240 ? bestManifest : null
}

function safeAssetName(value) {
  return normalized(value)
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
}

function pluginIconValues(manifest) {
  if (!manifest) return []

  var result = []
  var barWidget = manifest.barWidget || ({})
  pushUnique(result, manifest.icon)
  pushUnique(result, barWidget.icon)

  var sourceDir = String(manifest.__sourceDir || "").replace(/\/$/, "")
  if (!sourceDir) return result

  var names = []
  pushUnique(names, safeAssetName(manifest.id))
  pushUnique(names, safeAssetName(finalSegment(manifest.id)))
  pushUnique(names, safeAssetName(manifest.name))
  pushUnique(names, "icon")
  pushUnique(names, "logo")

  var extensions = ["svg", "png", "webp"]
  for (var i = 0; i < names.length; i++) {
    for (var j = 0; j < extensions.length; j++) {
      pushUnique(result, sourceDir + "/assets/" + names[i] + "." + extensions[j])
      pushUnique(result, sourceDir + "/" + names[i] + "." + extensions[j])
    }
  }

  return result
}

function titleScore(entry, titles) {
  var values = candidateValues(titles)
  var name = normalized(entry && entry.name)
  var commands = commandTokens(entry)
  if (!name) return -1

  var best = -1
  for (var i = 0; i < values.length; i++) {
    var title = values[i]
    if (title === name) best = Math.max(best, 780)
    if (compact(title).length >= 4 && compact(title) === compact(name))
      best = Math.max(best, 770)
    for (var j = 0; j < commands.length; j++)
      if (compact(title).length >= 4 && compact(title) === compact(commands[j]))
        best = Math.max(best, 760)
    if (name.length >= 4 && (title.indexOf(name + " - ") === 0
        || title.indexOf(name + " — ") === 0
        || title.indexOf(name + " | ") === 0)) best = Math.max(best, 740)
  }
  return best
}

function matchScore(entry, candidates, titles) {
  if (!entry) return -1

  var ids = candidateValues(candidates)
  if (!ids.length && !candidateValues(titles).length) return -1

  var entryId = normalized(entry.id)
  var startupClass = normalized(entry.startupClass)
  var commands = commandTokens(entry)
  var name = normalized(entry.name)
  var best = Math.max(webAppScore(entry, candidates),
    steamScore(entry, candidates), titleScore(entry, titles))

  for (var i = 0; i < ids.length; i++) {
    var id = ids[i]
    var idCompact = compact(id)
    var idTail = finalSegment(id)

    if (entryId === id) best = Math.max(best, 1000)
    if (startupClass && startupClass === id) best = Math.max(best, 980)
    if (commands.indexOf(id) !== -1) best = Math.max(best, 940)
    if (name && name === id) best = Math.max(best, 900)

    if (idCompact.length >= 4) {
      if (compact(entryId) === idCompact) best = Math.max(best, 880)
      if (startupClass && compact(startupClass) === idCompact) best = Math.max(best, 870)
    }

    if (idTail.length >= 3) {
      if (finalSegment(entryId) === idTail) best = Math.max(best, 820)
      if (startupClass && finalSegment(startupClass) === idTail) best = Math.max(best, 810)
      if (commands.indexOf(idTail) !== -1) best = Math.max(best, 800)
    }
  }

  return best
}

function resolve(entries, candidates, titles) {
  var values = entries || []
  var bestEntry = null
  var bestScore = -1

  for (var i = 0; i < values.length; i++) {
    var entry = values[i]
    var score = matchScore(entry, candidates, titles)
    if (score > bestScore) {
      bestEntry = entry
      bestScore = score
    }
  }

  return bestScore >= 740 ? bestEntry : null
}

function appendUnique(target, values) {
  for (var i = 0; i < values.length; i++) pushUnique(target, values[i])
}

function resolveWindow(entries, manifests, window) {
  var info = window || ({})
  var candidates = [info.appClass, info.initialClass, info.executableName]
  if (/^\d+$/.test(String(info.steamAppId || "")))
    candidates.push("steam_app_" + String(info.steamAppId))
  var titles = [info.title, info.initialTitle]
  var plugin = resolvePlugin(manifests, titles, candidates)
  var entry = plugin
    ? resolve(entries, pluginCandidates(plugin), [])
    : resolve(entries, candidates, titles)
  var icons = []

  if (entry && entry.icon) pushUnique(icons, entry.icon)
  appendUnique(icons, steamIconNames(candidates))

  var steamIds = steamAppIds(candidates)
  return {
    entry: entry,
    plugin: plugin,
    iconNames: icons,
    steamAppId: steamIds.length ? steamIds[0] : ""
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    normalized: normalized,
    compact: compact,
    finalSegment: finalSegment,
    executableName: executableName,
    commandText: commandText,
    commandTokens: commandTokens,
    normalizedHost: normalizedHost,
    webAppUrls: webAppUrls,
    hostFromUrl: hostFromUrl,
    appIds: appIds,
    webAppIdentity: webAppIdentity,
    webAppScore: webAppScore,
    steamAppIds: steamAppIds,
    steamEntryAppIds: steamEntryAppIds,
    steamScore: steamScore,
    steamIconNames: steamIconNames,
    candidateValues: candidateValues,
    pluginTitleCandidates: pluginTitleCandidates,
    pluginCandidates: pluginCandidates,
    isQuickshellWindow: isQuickshellWindow,
    pluginTitleScore: pluginTitleScore,
    resolvePlugin: resolvePlugin,
    safeAssetName: safeAssetName,
    pluginIconValues: pluginIconValues,
    titleScore: titleScore,
    matchScore: matchScore,
    resolve: resolve,
    resolveWindow: resolveWindow
  }
}
