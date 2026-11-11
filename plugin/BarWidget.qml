import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Muse companion widget for the Omarchy bar.
//
// Shows the link state of this machine's Muse gadget service
// (musegadget.service, from Meta's Muse Gadgets SDK) as a status dot
// next to a label: green while the service is active, red while it is
// not, grey until the first check lands. Clicking the widget launches
// Muse (the muse-ai launcher from the OmaMetaMuse package by default).
//
// IPC, from a terminal:
//   omarchy-shell io.github.microhustlestack.muse status   -> active / inactive / ...
//   omarchy-shell io.github.microhustlestack.muse refresh
//   omarchy-shell io.github.microhustlestack.muse launch
BarWidget {
  id: root
  moduleName: "io.github.microhustlestack.muse"

  readonly property string label: setting("label", "Muse")
  readonly property bool showLabel: setting("showLabel", true)
  readonly property int refreshSeconds: setting("refreshSeconds", 30)
  readonly property string serviceName: setting("serviceName", "musegadget.service")
  readonly property string launchCommand: setting("launchCommand", "muse-ai")

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
    command: ["muse-ai"]
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

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.showLabel && !root.vertical
      text: root.label
      color: root.fg
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.launch()
  }
}
