import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Ui

// Muse companion widget for the Omarchy bar.
//
// Shows the link state of this machine's Muse gadget service
// (musegadget.service, from Meta's Muse Gadgets SDK) as a status dot
// next to the Muse icon: green while the service is active, red while
// it is not, grey until the first check lands. Clicking the widget
// opens Muse as a webapp (Omarchy's omarchy-launch-webapp by default).
//
// IPC, from a terminal:
//   omarchy-shell io.github.microhustlestack.muse status   -> active / inactive / ...
//   omarchy-shell io.github.microhustlestack.muse refresh
//   omarchy-shell io.github.microhustlestack.muse launch
BarWidget {
  id: root
  moduleName: "io.github.microhustlestack.muse"

  readonly property string iconName: setting("iconName", "muse-ai")
  readonly property string label: setting("label", "Muse")
  readonly property bool showLabel: setting("showLabel", false)
  readonly property int refreshSeconds: Math.max(5, Math.min(300, Number(setting("refreshSeconds", 30)) || 30))
  readonly property string serviceName: setting("serviceName", "musegadget.service")
  readonly property string launchCommand: setting("launchCommand", "omarchy-launch-webapp https://muse.ai/")

  // Themed icon for the bar; empty when the icon theme has no match, in
  // which case the text label takes its place so the widget never
  // renders blank.
  readonly property string iconSource: Quickshell.iconPath(root.iconName, true)
  readonly property bool hasIcon: iconSource.length > 0

  // Raw `systemctl is-active` answer: "active", "inactive", "failed",
  // or "" while the first check is still running.
  property string linkState: ""

  readonly property bool linked: linkState === "active"
  readonly property color dotColor: linkState === "" ? Color.muted : (linked ? "#7fc348" : Color.urgent)
  readonly property color fg: bar ? bar.barForeground : Color.foreground

  // Click contract used by the bar host. The host only dispatches a press
  // to a target that exposes triggerPress(), so the widget root, not the
  // MouseArea, is the registered target.
  property bool interactive: true
  property bool pressable: true
  property bool concealed: false
  property int heldButtons: Qt.NoButton
  property var registeredBar: null
  readonly property bool tooltipHovered: visible && interactive && !concealed && mouseArea.containsMouse
  readonly property string tooltipText: {
    if (root.linkState === "") return "Muse: checking the gadget service..."
    if (root.linked) return "Muse gadget service active. Click to open Muse."
    return "Muse gadget service " + root.linkState + ". Click to open Muse."
  }
  readonly property real pressScale: root.pressable
    && ((mouseArea.pressedButtons | root.heldButtons) & (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton))
    ? 0.9 : 1

  function refresh() {
    if (statusProc.running) return
    checkTimeout.restart()
    statusProc.running = true
  }

  function launch() {
    if (root.bar && typeof root.bar.run === "function") {
      root.bar.run(root.launchCommand)
    } else {
      Quickshell.execDetached(["bash", "-lc", root.launchCommand])
    }
  }

  function triggerPress(button) {
    if (root.bar && typeof root.bar.hideTooltip === "function") root.bar.hideTooltip(root)
    if (button === Qt.MiddleButton) root.broadcast("refresh")
    else if (button === Qt.LeftButton) root.launch()
  }

  function syncClickRegistration() {
    if (registeredBar && typeof registeredBar.unregisterClickTarget === "function")
      registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && typeof registeredBar.registerClickTarget === "function")
      registeredBar.registerClickTarget(root)
  }

  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: {
    if (registeredBar && typeof registeredBar.unregisterClickTarget === "function")
      registeredBar.unregisterClickTarget(root)
  }
  onVisibleChanged: if (!visible && root.bar) root.bar.hideTooltip(root)
  onInteractiveChanged: if (!interactive && root.bar) root.bar.hideTooltip(root)
  onConcealedChanged: if (concealed && root.bar) root.bar.hideTooltip(root)
  onLinkStateChanged: if (mouseArea.containsMouse && root.bar) root.bar.showTooltip(root, root.tooltipText)

  implicitWidth: root.vertical ? root.barSize : content.implicitWidth + Style.space(16)
  implicitHeight: root.vertical ? Math.max(root.barSize, content.implicitHeight + Style.space(8)) : root.barSize

  Behavior on pressScale {
    NumberAnimation {
      duration: Style.duration(160)
      easing.type: Easing.Bezier
      easing.bezierCurve: Style.easeOut
    }
  }

  Grid {
    id: content
    anchors.centerIn: parent
    columns: root.vertical ? 1 : 3
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    columnSpacing: root.vertical ? 0 : Style.space(6)
    rowSpacing: root.vertical ? Style.space(2) : 0
    scale: root.pressScale

    Rectangle {
      width: Math.max(6, Style.space(8))
      height: width
      radius: width / 2
      color: root.dotColor
    }

    IconImage {
      visible: root.hasIcon
      implicitSize: Style.bar.iconCanvas
      source: root.iconSource
    }

    Text {
      visible: !root.vertical && (root.showLabel || !root.hasIcon)
      text: root.label
      textFormat: Text.PlainText
      color: root.fg
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }

  Process {
    id: statusProc
    command: ["systemctl", "is-active", "--", root.serviceName]
    stdout: StdioCollector {
      onStreamFinished: {
        checkTimeout.stop()
        root.linkState = text.trim() || "unavailable"
      }
    }
  }

  Timer {
    id: checkTimeout
    interval: 4000
    onTriggered: {
      statusProc.running = false
      root.linkState = "unavailable"
    }
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "io.github.microhustlestack.muse"
    function status(): string { return root.linkState || "unknown" }
    function refresh(): void { root.broadcast("refresh") }
    function launch(): void { root.launch() }
  }

  // The bar host owns pointer input over widget slots (for dragging and
  // panel marks), so a plain MouseArea never sees a click on its own.
  // triggerPress() above is the path the host uses. The MouseArea remains
  // as a fallback for shells that do not register click targets, and it
  // also owns hover for the tooltip.
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: root.pressable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltipText)
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(mouse) { if (root.pressable) root.triggerPress(mouse.button) }
  }
}
