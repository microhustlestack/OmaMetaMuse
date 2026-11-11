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
  readonly property int refreshSeconds: setting("refreshSeconds", 30)
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
  readonly property color dotColor: linkState === "" ? "#888888" : (linked ? "#7fc348" : "#e5484d")
  readonly property color fg: bar ? bar.barForeground : Color.foreground

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function launch() {
    launchProc.command = launchCommand.split(" ").filter(function (s) { return s.length > 0 })
    launchProc.running = true
  }

  implicitWidth: row.implicitWidth + 16
  implicitHeight: row.implicitHeight

  Process {
    id: statusProc
    command: ["systemctl", "is-active", root.serviceName]
    stdout: StdioCollector {
      onStreamFinished: root.linkState = text.trim()
    }
  }

  Process {
    id: launchProc
    command: ["omarchy-launch-webapp", "https://muse.ai/"]
  }

  Timer {
    interval: Math.max(5, root.refreshSeconds) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "io.github.microhustlestack.muse"
    function status(): string { return root.linkState }
    function refresh(): void { root.refresh() }
    function launch(): void { root.launch() }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 8
      height: 8
      radius: 4
      color: root.dotColor
    }

    IconImage {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.hasIcon && !root.vertical
      implicitSize: 18
      source: root.iconSource
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.vertical && (root.showLabel || !root.hasIcon)
      text: root.label
      color: root.fg
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
    }
  }

  // The bar host owns pointer input over widget slots (for dragging and
  // panel marks), so a plain MouseArea in a third-party widget never sees a
  // click. Registering the MouseArea as a click target with the injected
  // bar API is what lets its clicks through. The bar is injected after the
  // widget is created, so registration syncs whenever it changes.
  function syncClickRegistration() {
    if (root.bar && typeof root.bar.registerClickTarget === "function")
      root.bar.registerClickTarget(clickArea)
  }

  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: {
    if (root.bar && typeof root.bar.unregisterClickTarget === "function")
      root.bar.unregisterClickTarget(clickArea)
  }

  MouseArea {
    id: clickArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.launch()
  }
}
