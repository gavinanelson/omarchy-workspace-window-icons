import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "AppIconModel.js" as AppIconModel

BarWidget {
  id: root
  moduleName: "gavinanelson.workspace-window-icons"

  property int eventSerial: 0
  property bool settingsOpen: false
  readonly property bool opened: settingsOpen
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property var desktopEntries: DesktopEntries.applications
    ? DesktopEntries.applications.values : []
  readonly property int configuredIconSize: Math.max(12, Number(setting("iconSize", 18)))
  readonly property int iconSize: Math.min(configuredIconSize, Math.max(12, barSize - Style.space(8)))
  readonly property int itemGap: Math.max(0, Number(setting("itemGap", 3)))
  readonly property real inactiveOpacity: Math.max(0.2,
    Math.min(1, Number(setting("inactiveOpacity", 100)) / 100))
  readonly property real saturationEffect: {
    var percent = Math.max(0, Math.min(200, Number(setting("iconSaturation", 100))))
    return (percent - 100) / 100
  }

  // Mirror the old Niri task strip: tiled windows first in their physical
  // scrolling order, then floating windows. Hyprland's scrolling layout keeps
  // off-screen columns in this same coordinate space, so they remain visible
  // here even when they are outside the monitor viewport.
  readonly property var workspaceWindows: {
    var dependency = eventSerial
    var workspace = Hyprland.focusedWorkspace
    if (!workspace || !workspace.toplevels) return []

    var result = []
    var values = workspace.toplevels.values
    for (var i = 0; i < values.length; i++) result.push(values[i])
    result.sort(function(left, right) {
      var leftIpc = left && left.lastIpcObject ? left.lastIpcObject : ({})
      var rightIpc = right && right.lastIpcObject ? right.lastIpcObject : ({})
      var leftFloating = leftIpc.floating === true ? 1 : 0
      var rightFloating = rightIpc.floating === true ? 1 : 0
      if (leftFloating !== rightFloating) return leftFloating - rightFloating

      var leftAt = leftIpc.at || [999999, 999999]
      var rightAt = rightIpc.at || [999999, 999999]
      var leftX = Number(leftAt[0] === undefined ? 999999 : leftAt[0])
      var rightX = Number(rightAt[0] === undefined ? 999999 : rightAt[0])
      if (leftX !== rightX) return leftX - rightX
      var leftY = Number(leftAt[1] === undefined ? 999999 : leftAt[1])
      var rightY = Number(rightAt[1] === undefined ? 999999 : rightAt[1])
      if (leftY !== rightY) return leftY - rightY
      return String(left.address || "").localeCompare(String(right.address || ""))
    })
    return result
  }

  visible: !vertical && workspaceWindows.length > 0
  implicitWidth: visible ? windowRow.implicitWidth + Style.space(4) : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  function resolveIconSource(icon) {
    var value = String(icon || "")
    if (bar && bar.shell && bar.shell.appLibrary) return bar.shell.appLibrary.iconSource(value)
    if (!value) return Quickshell.iconPath("application-x-executable", true)
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/") return Util.fileUrl(value)
    return Quickshell.iconPath(value, true)
      || Quickshell.iconPath("application-x-executable", true)
  }

  function focusWindow(toplevel) {
    if (!toplevel) return
    if (toplevel.wayland) toplevel.wayland.activate()
    else {
      var ipc = toplevel.lastIpcObject || ({})
      Hyprland.dispatch("focuswindow address:" + String(ipc.address || toplevel.address || ""))
    }
  }

  function closeWindow(toplevel) {
    if (!toplevel) return
    if (toplevel.wayland) toplevel.wayland.close()
    else Hyprland.dispatch("closewindow address:" + String(toplevel.address || ""))
  }

  function close() { settingsOpen = false }
  function open() { settingsOpen = true }
  function toggle() { settingsOpen = !settingsOpen }

  function previewSetting(key, value) {
    var next = Object.assign({}, settings || {})
    next[key] = value
    settings = next
  }

  function saveSetting(key, value) {
    previewSetting(key, value)
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(moduleName, settings)
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      // Make geometry ordering and focus styling react immediately to all
      // compositor events, including scrolling-layout moves.
      Hyprland.refreshToplevels()
      root.eventSerial++
    }
  }

  Row {
    id: windowRow
    anchors.centerIn: parent
    spacing: root.itemGap

    Repeater {
      // Repeat by slot and resolve the toplevel through the freshly sorted
      // array. Repeating the QObject array directly lets QML reuse delegates
      // with stale modelData when a window is inserted in the middle.
      model: root.workspaceWindows.length

      Item {
        id: windowButton
        required property int index

        readonly property var toplevel: root.workspaceWindows[index]
        readonly property var ipc: toplevel && toplevel.lastIpcObject
          ? toplevel.lastIpcObject : ({})
        readonly property string appClass: String(ipc.class || "")
        readonly property string initialClass: String(ipc.initialClass || "")
        readonly property int pid: Number(ipc.pid || 0)
        readonly property string title: String(
          (toplevel ? toplevel.title : "") || ipc.title || appClass || "Application")
        readonly property string windowAddress: String(ipc.address
          || (toplevel ? toplevel.address : "") || "")
        readonly property var activeIpc: Hyprland.activeToplevel
          && Hyprland.activeToplevel.lastIpcObject
          ? Hyprland.activeToplevel.lastIpcObject : ({})
        readonly property string activeAddress: String(activeIpc.address
          || (Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "") || "")
        readonly property bool focused: !!toplevel && (activeAddress
          ? windowAddress === activeAddress : toplevel.activated)
        property string executablePath: ""
        readonly property string executableName: {
          var path = executablePath
          return path ? path.slice(path.lastIndexOf("/") + 1) : ""
        }
        readonly property var desktopEntry: AppIconModel.resolve(root.desktopEntries,
          [appClass, initialClass, executableName])
        readonly property string iconName: desktopEntry
          ? String(desktopEntry.icon || "") : ""
        readonly property string iconSource: root.resolveIconSource(iconName)

        width: root.iconSize + Style.space(6)
        height: root.barSize

        function refreshExecutable() {
          executablePath = ""
          if (pid <= 0 || executableLookup.running) return
          executableLookup.command = ["readlink", "-f", "/proc/" + pid + "/exe"]
          executableLookup.running = true
        }

        onPidChanged: Qt.callLater(refreshExecutable)
        Component.onCompleted: refreshExecutable()

        Process {
          id: executableLookup
          stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: windowButton.executablePath = String(text || "").trim()
          }
        }

        Rectangle {
          id: focusSurface
          anchors.centerIn: parent
          width: root.iconSize + Style.space(8)
          height: Math.min(windowButton.height - Style.space(2), root.iconSize + Style.space(8))
          radius: Math.max(Style.space(7), Style.cornerRadius)
          color: Util.alpha(root.foreground, 0.24)
          border.width: Style.space(1)
          border.color: Util.alpha(root.foreground, 0.7)
          opacity: windowButton.focused ? 1 : 0
          scale: windowButton.focused ? 1 : 0.82
          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.foreground
            shadowOpacity: 0.5
            shadowBlur: 0.84
            shadowVerticalOffset: 1
            shadowScale: 1.08
          }

          Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        }

        Image {
          id: appIcon
          anchors.centerIn: parent
          width: root.iconSize
          height: root.iconSize
          source: windowButton.iconSource
          sourceSize.width: Math.round(width * Screen.devicePixelRatio)
          sourceSize.height: Math.round(height * Screen.devicePixelRatio)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          mipmap: true
          opacity: windowButton.focused ? 1 : root.inactiveOpacity
          scale: windowButton.focused ? 1.05 : 1
          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            saturation: root.saturationEffect
            shadowEnabled: windowButton.focused
            shadowColor: Qt.rgba(0, 0, 0, 0.9)
            shadowOpacity: 0.52
            shadowBlur: 0.38
            shadowVerticalOffset: 1
          }

          Behavior on opacity { NumberAnimation { duration: 100 } }
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
        }

        Text {
          anchors.centerIn: parent
          visible: appIcon.status === Image.Error
          text: "󰖯"
          color: root.foreground
          opacity: windowButton.focused ? 1 : root.inactiveOpacity
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.settingsOpen = !root.settingsOpen
            else if (mouse.button === Qt.MiddleButton) root.closeWindow(windowButton.toplevel)
            else {
              root.settingsOpen = false
              root.focusWindow(windowButton.toplevel)
            }
          }
          onEntered: if (root.bar) {
            var appName = windowButton.desktopEntry
              ? String(windowButton.desktopEntry.name || "") : windowButton.appClass
            var state = windowButton.focused ? "Focused" : "Open in this workspace"
            root.bar.showTooltip(windowButton,
              windowButton.title + (appName ? "\n" + appName : "") + "\n" + state)
          }
          onExited: if (root.bar) root.bar.hideTooltip(windowButton)
        }
      }
    }
  }

  PopupCard {
    id: settingsPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.settingsOpen
    contentWidth: fittedContentWidth(Style.space(330))
    contentHeight: fittedContentHeight(settingsColumn.implicitHeight)

    Column {
      id: settingsColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        text: "WORKSPACE WINDOW ICONS"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Text {
        width: parent.width
        text: "Windows follow their scrolling-layout order. The softly raised icon is focused."
        wrapMode: Text.WordWrap
        color: root.bar ? Qt.darker(root.bar.foreground, 1.45) : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      PanelSeparator { foreground: root.bar ? root.bar.foreground : Color.foreground }

      SettingSlider {
        label: "Icon saturation"
        suffix: "%"
        minimum: 0
        maximum: 200
        step: 5
        currentValue: Number(root.setting("iconSaturation", 100))
        onPreviewed: function(value) { root.previewSetting("iconSaturation", Math.round(value)) }
        onCommitted: function(value) { root.saveSetting("iconSaturation", Math.round(value)) }
      }

      SettingSlider {
        label: "Icon size"
        suffix: "px"
        minimum: 12
        maximum: 24
        step: 1
        currentValue: Number(root.setting("iconSize", 18))
        onPreviewed: function(value) { root.previewSetting("iconSize", Math.round(value)) }
        onCommitted: function(value) { root.saveSetting("iconSize", Math.round(value)) }
      }

      SettingSlider {
        label: "Inactive opacity"
        suffix: "%"
        minimum: 20
        maximum: 100
        step: 5
        currentValue: Number(root.setting("inactiveOpacity", 100))
        onPreviewed: function(value) { root.previewSetting("inactiveOpacity", Math.round(value)) }
        onCommitted: function(value) { root.saveSetting("inactiveOpacity", Math.round(value)) }
      }

      SettingSlider {
        label: "Icon spacing"
        suffix: "px"
        minimum: 0
        maximum: 12
        step: 1
        currentValue: Number(root.setting("itemGap", 3))
        onPreviewed: function(value) { root.previewSetting("itemGap", Math.round(value)) }
        onCommitted: function(value) { root.saveSetting("itemGap", Math.round(value)) }
      }
    }
  }

  component SettingSlider: Column {
    id: sliderSetting

    required property string label
    property string suffix: ""
    required property real minimum
    required property real maximum
    required property real step
    required property real currentValue

    signal previewed(real value)
    signal committed(real value)

    width: parent ? parent.width : implicitWidth
    spacing: Style.space(5)

    Item {
      width: parent.width
      implicitHeight: Math.max(settingLabel.implicitHeight, settingValue.implicitHeight)

      Text {
        id: settingLabel
        anchors.left: parent.left
        text: sliderSetting.label
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
      }

      Text {
        id: settingValue
        anchors.right: parent.right
        text: Math.round(slider.dragging ? slider.liveValue : sliderSetting.currentValue)
          + sliderSetting.suffix
        color: root.bar ? Qt.darker(root.bar.foreground, 1.35) : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    PanelSlider {
      id: slider
      width: parent.width
      bar: root.bar
      minimum: sliderSetting.minimum
      maximum: sliderSetting.maximum
      step: sliderSetting.step
      integer: true
      value: sliderSetting.currentValue
      onMoved: function(value) { sliderSetting.previewed(value) }
      onReleased: function(value) { sliderSetting.committed(value) }
    }
  }
}
