function ipcOf(window) {
  return window && window.lastIpcObject ? window.lastIpcObject : ({})
}

function coordinate(ipc, index) {
  var at = ipc && ipc.at
  if (!at || at[index] === undefined || at[index] === null) return 999999
  var value = Number(at[index])
  return isFinite(value) ? value : 999999
}

function addressOf(window) {
  var ipc = ipcOf(window)
  return String(ipc.address || (window ? window.address : "") || "")
}

function compareWindows(left, right) {
  var leftIpc = ipcOf(left)
  var rightIpc = ipcOf(right)
  var leftFloating = leftIpc.floating === true ? 1 : 0
  var rightFloating = rightIpc.floating === true ? 1 : 0

  if (leftFloating !== rightFloating) return leftFloating - rightFloating

  var leftX = coordinate(leftIpc, 0)
  var rightX = coordinate(rightIpc, 0)
  if (leftX !== rightX) return leftX - rightX

  var leftY = coordinate(leftIpc, 1)
  var rightY = coordinate(rightIpc, 1)
  if (leftY !== rightY) return leftY - rightY

  return addressOf(left).localeCompare(addressOf(right))
}

function orderedAddresses(clients, workspaceId) {
  var matching = []
  var source = clients || []
  var wanted = Number(workspaceId)

  for (var i = 0; i < source.length; i++) {
    var client = source[i]
    var clientWorkspace = client && client.workspace ? Number(client.workspace.id) : NaN
    if (client && clientWorkspace === wanted)
      matching.push({ lastIpcObject: client })
  }

  matching.sort(compareWindows)

  var addresses = []
  for (var j = 0; j < matching.length; j++)
    addresses.push(addressOf(matching[j]))
  return addresses
}

function sortedWindows(values, preferredAddresses) {
  var result = []
  var source = values || []
  for (var i = 0; i < source.length; i++) {
    if (source[i]) result.push(source[i])
  }

  var ranks = ({})
  var preferred = preferredAddresses || []
  for (var j = 0; j < preferred.length; j++) ranks[String(preferred[j])] = j

  result.sort(function(left, right) {
    var leftAddress = addressOf(left)
    var rightAddress = addressOf(right)
    var leftRank = ranks[leftAddress]
    var rightRank = ranks[rightAddress]
    var leftKnown = leftRank !== undefined
    var rightKnown = rightRank !== undefined

    if (leftKnown && rightKnown && leftRank !== rightRank) return leftRank - rightRank
    if (leftKnown !== rightKnown) return leftKnown ? -1 : 1
    return compareWindows(left, right)
  })
  return result
}

if (typeof module !== "undefined") {
  module.exports = {
    ipcOf: ipcOf,
    coordinate: coordinate,
    addressOf: addressOf,
    compareWindows: compareWindows,
    orderedAddresses: orderedAddresses,
    sortedWindows: sortedWindows
  }
}
