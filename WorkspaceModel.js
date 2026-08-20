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

function sortedWindows(values) {
  var result = []
  var source = values || []
  for (var i = 0; i < source.length; i++) {
    if (source[i]) result.push(source[i])
  }
  result.sort(compareWindows)
  return result
}

if (typeof module !== "undefined") {
  module.exports = {
    ipcOf: ipcOf,
    coordinate: coordinate,
    addressOf: addressOf,
    compareWindows: compareWindows,
    sortedWindows: sortedWindows
  }
}
