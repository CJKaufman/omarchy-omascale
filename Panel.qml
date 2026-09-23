import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "cjkaufman.omascale"
  ipcTarget: "cjkaufman.omascale"
  manageIpc: false

  IpcHandler {
    target: root.ipcTarget
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
    function refresh() { root.runHelper(["sync"]) }
  }


  // Material Design & Nerd Font Glyphs
  readonly property string glyphTailscale: "󱚵"
  readonly property string glyphExitNode: "󰄛"
  readonly property string glyphDirect: "󰈀"
  readonly property string glyphLan: "󰲝"
  readonly property string glyphPing: "󰀦"
  readonly property string glyphCopy: "󰆏"
  readonly property string glyphCheck: "󰄬"
  readonly property string glyphRefresh: "󰑐"
  readonly property string glyphSearch: "󰍉"
  readonly property string glyphExternal: "󰌹"
  readonly property string glyphLinux: "󰌽"
  readonly property string glyphWindows: "󰍲"
  readonly property string glyphAndroid: "󰀲"
  readonly property string glyphApple: "󰀵"
  readonly property string glyphDevice: "󰟀"

  readonly property string helper: Qt.resolvedUrl("bin/omascale").toString().replace("file://", "")

  // Theme & Styling
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color successColor: "#4EBA6F"
  readonly property color dim: Qt.darker(foreground, 1.6)
  readonly property color subtleBg: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
  readonly property color cardBg: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04)
  readonly property color borderCol: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Plugin Settings
  readonly property int refreshIntervalSec: Math.max(5, Number(setting("refreshIntervalSec", 10)))
  readonly property bool showIpOnBar: Boolean(setting("showIpOnBar", false))

  // Live Telemetry State
  property bool connected: false
  property string backendState: "Checking"
  property string selfHostname: "This Device"
  property string selfDnsName: ""
  property string selfIpv4: ""
  property string selfIpv6: ""
  property string selfOs: "linux"
  property bool isRoutingExit: false
  property string activeExitName: ""
  property string activeExitIp: ""
  property bool lanAccess: false
  property var exitNodes: []
  property var peers: []
  property int totalPeers: 0
  property int onlinePeers: 0

  // Interactive View Filter State
  property string searchQuery: ""
  property string filterMode: "all" // "all" | "online" | "exit" | "offline"
  property var pingCache: ({})
  property string activePingIp: ""
  property string lastCopiedIp: ""

  // Reactive State Watcher from safe_write_state
  FileView {
    id: stateWatcher
    path: Quickshell.env("HOME") + "/.local/state/omarchy/cjkaufman.omascale/state.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.parseState(text())
    onFileChanged: reload()
    Component.onCompleted: reload()
  }

  function parseState(raw) {
    try {
      if (!raw || raw.trim() === "") return
      var s = JSON.parse(raw)
      root.connected = s.connected === true
      root.backendState = String(s.backend_state || "Offline")

      if (s.self) {
        root.selfHostname = String(s.self.hostname || "This Device")
        root.selfDnsName = String(s.self.dns_name || "")
        root.selfIpv4 = String(s.self.ipv4 || "")
        root.selfIpv6 = String(s.self.ipv6 || "")
        root.selfOs = String(s.self.os || "linux")
        root.isRoutingExit = s.self.is_routing_exit === true
        root.activeExitName = String(s.self.active_exit_node_name || "")
        root.activeExitIp = String(s.self.active_exit_node_ip || "")
        root.lanAccess = s.self.lan_access === true
      }

      root.exitNodes = Array.isArray(s.exit_nodes) ? s.exit_nodes : []
      root.peers = Array.isArray(s.peers) ? s.peers : []
      root.totalPeers = Number(s.total_peers || root.peers.length)
      root.onlinePeers = Number(s.online_peers || 0)
    } catch (e) {
      console.warn("omascale state parse error", e)
    }
  }

  // Periodic Poller
  Timer {
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.runHelper(["sync"])
  }

  // Copy Feedback Reset Timer
  Timer {
    id: copyResetTimer
    interval: 2000
    repeat: false
    onTriggered: root.lastCopiedIp = ""
  }

  // Command Runner Process
  Process {
    id: helperProc
    onExited: function(exitCode, exitStatus) {
      stateWatcher.reload()
    }
  }

  function runHelper(args) {
    helperProc.command = [root.helper].concat(args)
    helperProc.running = true
  }

  // Dedicated Ping Process
  Process {
    id: pingProc
    property string targetIp: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var res = JSON.parse(String(text || "{}"))
          if (res.ip) {
            var updated = Object.assign({}, root.pingCache)
            updated[res.ip] = {
              latency: res.latency || "Timeout",
              direct: res.direct === true,
              success: res.success === true
            }
            root.pingCache = updated
          }
        } catch (e) {}
        root.activePingIp = ""
      }
    }
  }

  function pingPeer(ip) {
    if (!ip || root.activePingIp) return
    root.activePingIp = ip
    pingProc.targetIp = ip
    pingProc.command = [root.helper, "ping", ip]
    pingProc.running = true
  }

  function copyIp(ip, label) {
    if (!ip) return
    Quickshell.clipboardText = ip
    root.lastCopiedIp = ip
    copyResetTimer.restart()
    runHelper(["copy", ip, label || "Device"])
  }

  function osGlyph(osName) {
    var o = String(osName || "").toLowerCase()
    if (o.indexOf("linux") !== -1) return root.glyphLinux
    if (o.indexOf("windows") !== -1) return root.glyphWindows
    if (o.indexOf("android") !== -1) return root.glyphAndroid
    if (o.indexOf("ios") !== -1 || o.indexOf("darwin") !== -1 || o.indexOf("mac") !== -1) return root.glyphApple
    return root.glyphDevice
  }

  function filteredPeers() {
    var list = root.peers || []
    var query = root.searchQuery.trim().toLowerCase()
    var mode = root.filterMode

    return list.filter(function(p) {
      // Category filter
      if (mode === "online" && !p.online) return false
      if (mode === "offline" && p.online) return false
      if (mode === "exit" && !p.is_exit_node) return false

      // Search filter
      if (query !== "") {
        var h = String(p.hostname || "").toLowerCase()
        var d = String(p.dns_name || "").toLowerCase()
        var ip = String(p.ipv4 || "")
        if (h.indexOf(query) === -1 && d.indexOf(query) === -1 && ip.indexOf(query) === -1) {
          return false
        }
      }
      return true
    })
  }

  // Component sizing
  implicitWidth: barButton.implicitWidth
  implicitHeight: barButton.implicitHeight
  width: implicitWidth
  height: implicitHeight

  // Top Bar Button
  WidgetButton {
    id: barButton
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    activeColor: root.accent
    useActiveColor: true
    labelVisible: true
    fontSize: Style.font.body

    text: {
      var parts = []
      parts.push(root.glyphTailscale)
      if (root.connected) {
        if (root.isRoutingExit) {
          parts.push(root.glyphExitNode + " " + (root.activeExitName || "Exit"))
        }
        if (root.showIpOnBar && root.selfIpv4) {
          parts.push(root.selfIpv4)
        }
      } else {
        parts.push("Off")
      }
      return parts.join(" ")
    }

    tooltipText: {
      if (!root.connected) {
        return "Tailscale: Offline (Click to open OmaScale)"
      }
      var lines = [
        "Tailscale: Running (" + (root.onlinePeers) + "/" + (root.totalPeers) + " peers online)",
        "IP: " + (root.selfIpv4 || "Acquiring..."),
        root.isRoutingExit ? ("Exit Node: " + root.activeExitName + " (" + root.activeExitIp + ")") : "Internet: Direct Connection",
        "",
        "Left-Click: Open OmaScale Network Manager"
      ]
      return lines.join("\n")
    }

    onPressed: function(btn) {
      root.toggle()
    }
  }

  // Interactive Popup Window
  KeyboardPanel {
    id: panel
    anchorItem: barButton
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(menuCol.implicitHeight + Style.space(24), Style.space(580))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: menuCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: menuCol
          width: parent.width
          spacing: Style.space(10)

          // 1. Host Hero Card
          Rectangle {
            width: parent.width
            implicitHeight: heroCol.implicitHeight + Style.space(16)
            color: root.cardBg
            radius: 8
            border.color: root.borderCol
            border.width: 1

            ColumnLayout {
              id: heroCol
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(6)

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(8)

                Text {
                  text: root.glyphTailscale
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title * 1.2
                  color: root.connected ? root.accent : root.dim
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  RowLayout {
                    spacing: Style.space(6)

                    Text {
                      text: root.selfHostname
                      textFormat: Text.PlainText
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      color: root.foreground
                    }

                    Rectangle {
                      implicitWidth: Style.space(8)
                      implicitHeight: Style.space(8)
                      radius: 4
                      color: root.connected ? root.successColor : root.urgent
                    }

                    Text {
                      text: root.connected ? "Connected" : "Disconnected"
                      textFormat: Text.PlainText
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      color: root.connected ? root.successColor : root.urgent
                    }
                  }

                  Text {
                    text: root.selfDnsName || "Tailscale Mesh Network"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.dim
                    elide: Text.ElideRight
                    Layout.maximumWidth: Style.space(260)
                  }
                }

                // Refresh Button
                Rectangle {
                  implicitWidth: Style.space(28)
                  implicitHeight: Style.space(28)
                  radius: 6
                  color: refreshArea.containsMouse ? root.subtleBg : "transparent"
                  border.color: refreshArea.containsMouse ? root.accent : root.borderCol
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: root.glyphRefresh
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: refreshArea.containsMouse ? root.accent : root.foreground
                  }

                  MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runHelper(["sync"])
                  }
                }
              }

              // Local IPv4 Card Pill with 1-Click Copy
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: Style.space(32)
                radius: 6
                color: selfIpArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15) : root.subtleBg
                border.color: (root.lastCopiedIp === root.selfIpv4) ? root.successColor : (selfIpArea.containsMouse ? root.accent : root.borderCol)
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(8)

                  Text {
                    text: "Local IP:"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.dim
                  }

                  Text {
                    text: root.selfIpv4 || "No Address"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: root.foreground
                  }

                  Item { Layout.fillWidth: true }

                  Text {
                    text: (root.lastCopiedIp === root.selfIpv4) ? (root.glyphCheck + " Copied!") : (root.glyphCopy + " Copy")
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: (root.lastCopiedIp === root.selfIpv4) ? root.successColor : root.accent
                  }
                }

                MouseArea {
                  id: selfIpArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.copyIp(root.selfIpv4, root.selfHostname)
                }
              }
            }
          }

          // 2. Exit Node Routing Card
          Rectangle {
            width: parent.width
            implicitHeight: exitCol.implicitHeight + Style.space(16)
            color: root.cardBg
            radius: 8
            border.color: root.borderCol
            border.width: 1

            ColumnLayout {
              id: exitCol
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(6)

                Text {
                  text: root.glyphExitNode
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  color: root.isRoutingExit ? root.accent : root.dim
                }

                Text {
                  text: "Exit Node Routing"
                  textFormat: Text.PlainText
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  color: root.foreground
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: root.isRoutingExit ? ("Routing: " + root.activeExitName) : "Direct Connection"
                  textFormat: Text.PlainText
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: root.isRoutingExit ? root.accent : root.dim
                }
              }

              // Exit Node Selector Pills
              Flow {
                Layout.fillWidth: true
                spacing: Style.space(6)

                // Option: Direct (No Exit Node)
                Rectangle {
                  implicitWidth: directLabel.implicitWidth + Style.space(16)
                  implicitHeight: Style.space(26)
                  radius: 5
                  color: !root.isRoutingExit ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22) : (directArea.containsMouse ? root.subtleBg : "transparent")
                  border.color: !root.isRoutingExit ? root.accent : root.borderCol
                  border.width: !root.isRoutingExit ? 2 : 1

                  RowLayout {
                    id: directLabel
                    anchors.centerIn: parent
                    spacing: Style.space(4)
                    Text {
                      text: root.glyphDirect
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      color: !root.isRoutingExit ? root.accent : root.foreground
                    }
                    Text {
                      text: "Direct (None)"
                      textFormat: Text.PlainText
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: !root.isRoutingExit
                      color: !root.isRoutingExit ? root.accent : root.foreground
                    }
                  }

                  MouseArea {
                    id: directArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runHelper(["set-exit-node", ""])
                  }
                }

                // Available Exit Nodes from Tailnet
                Repeater {
                  model: root.exitNodes

                  delegate: Rectangle {
                    id: nodePill
                    required property var modelData
                    property bool isSelected: root.isRoutingExit && (root.activeExitIp === modelData.ip || root.activeExitName === modelData.hostname)

                    implicitWidth: nodeRow.implicitWidth + Style.space(16)
                    implicitHeight: Style.space(26)
                    radius: 5
                    color: isSelected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22) : (pillArea.containsMouse ? root.subtleBg : "transparent")
                    border.color: isSelected ? root.accent : root.borderCol
                    border.width: isSelected ? 2 : 1

                    RowLayout {
                      id: nodeRow
                      anchors.centerIn: parent
                      spacing: Style.space(4)

                      Rectangle {
                        implicitWidth: Style.space(6)
                        implicitHeight: Style.space(6)
                        radius: 3
                        color: nodePill.modelData.online ? root.successColor : root.dim
                      }

                      Text {
                        text: String(nodePill.modelData.hostname || nodePill.modelData.ip)
                        textFormat: Text.PlainText
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: nodePill.isSelected
                        color: nodePill.isSelected ? root.accent : root.foreground
                      }
                    }

                    MouseArea {
                      id: pillArea
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.runHelper(["set-exit-node", String(nodePill.modelData.ip || nodePill.modelData.hostname)])
                    }
                  }
                }
              }

              // Allow LAN Access Toggle Row
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: Style.space(30)
                radius: 6
                color: root.subtleBg

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  spacing: Style.space(8)

                  Text {
                    text: root.glyphLan
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.lanAccess ? root.accent : root.dim
                  }

                  Text {
                    text: "Allow Local LAN Access (While on Exit Node)"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.foreground
                  }

                  Item { Layout.fillWidth: true }

                  Switch {
                    id: lanSwitch
                    checked: root.lanAccess
                    onToggled: root.runHelper(["set-lan-access", checked ? "true" : "false"])
                  }
                }
              }
            }
          }

          // 3. Search & Peer Filter Header
          RowLayout {
            width: parent.width
            spacing: Style.space(6)

            // Search Bar Input
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: Style.space(32)
              radius: 6
              color: root.cardBg
              border.color: searchInput.activeFocus ? root.accent : root.borderCol
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(6)

                Text {
                  text: root.glyphSearch
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: root.dim
                }

                TextInput {
                  id: searchInput
                  Layout.fillWidth: true
                  text: root.searchQuery
                  onTextChanged: root.searchQuery = text
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: root.foreground
                  clip: true

                  Text {
                    text: "Search devices by name or IP..."
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.dim
                    visible: !searchInput.text && !searchInput.activeFocus
                  }
                }

                Text {
                  text: "✕"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: root.dim
                  visible: searchInput.text.length > 0

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      searchInput.text = ""
                      root.searchQuery = ""
                    }
                  }
                }
              }
            }
          }

          // Filter Chips (All, Online, Exit Nodes, Offline)
          RowLayout {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: [
                { label: "All (" + root.totalPeers + ")", mode: "all" },
                { label: "Online (" + root.onlinePeers + ")", mode: "online" },
                { label: "Exit Nodes (" + root.exitNodes.length + ")", mode: "exit" },
                { label: "Offline (" + (root.totalPeers - root.onlinePeers) + ")", mode: "offline" }
              ]

              delegate: Rectangle {
                id: chip
                required property var modelData
                property bool isActive: root.filterMode === modelData.mode

                implicitWidth: chipLabel.implicitWidth + Style.space(12)
                implicitHeight: Style.space(24)
                radius: 4
                color: isActive ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2) : (chipArea.containsMouse ? root.subtleBg : "transparent")
                border.color: isActive ? root.accent : root.borderCol
                border.width: 1

                Text {
                  id: chipLabel
                  anchors.centerIn: parent
                  text: chip.modelData.label
                  textFormat: Text.PlainText
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption * 0.95
                  font.bold: chip.isActive
                  color: chip.isActive ? root.accent : root.foreground
                }

                MouseArea {
                  id: chipArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.filterMode = chip.modelData.mode
                }
              }
            }
          }

          // 4. Peer Directory List
          ColumnLayout {
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: root.filteredPeers()

              delegate: Rectangle {
                id: peerCard
                required property var modelData
                property string peerIp: String(modelData.ipv4 || "")
                property string peerHost: String(modelData.hostname || "Unknown")
                property var pingInfo: root.pingCache[peerIp] || null
                property bool isBeingPinged: root.activePingIp === peerIp

                Layout.fillWidth: true
                implicitHeight: peerRow.implicitHeight + Style.space(12)
                radius: 6
                color: peerCardArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07) : root.cardBg
                border.color: peerCardArea.containsMouse ? root.borderCol : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                border.width: 1

                RowLayout {
                  id: peerRow
                  anchors.fill: parent
                  anchors.margins: Style.space(8)
                  spacing: Style.space(8)

                  // OS Icon
                  Text {
                    text: root.osGlyph(peerCard.modelData.os)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    color: peerCard.modelData.online ? root.foreground : root.dim
                    Layout.alignment: Qt.AlignVCenter
                  }

                  // Device Details Column (Left side: expands to fill all available space)
                  ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(6)

                      Text {
                        text: peerCard.peerHost
                        textFormat: Text.PlainText
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        color: peerCard.modelData.online ? root.foreground : root.dim
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      Rectangle {
                        implicitWidth: Style.space(6)
                        implicitHeight: Style.space(6)
                        radius: 3
                        color: peerCard.modelData.online ? root.successColor : root.dim
                        Layout.alignment: Qt.AlignVCenter
                      }

                      Rectangle {
                        visible: peerCard.modelData.is_exit_node === true
                        implicitWidth: exitBadgeText.implicitWidth + Style.space(6)
                        implicitHeight: Style.space(16)
                        radius: 3
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                        border.color: root.accent
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                          id: exitBadgeText
                          anchors.centerIn: parent
                          text: "EXIT NODE"
                          textFormat: Text.PlainText
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption * 0.8
                          font.bold: true
                          color: root.accent
                        }
                      }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.space(4)

                      Text {
                        text: peerCard.peerIp
                        textFormat: Text.PlainText
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption * 0.95
                        color: root.dim
                      }

                      Text {
                        visible: peerCard.pingInfo !== null && peerCard.pingInfo !== undefined
                        text: peerCard.pingInfo ? ("· " + peerCard.pingInfo.latency + (peerCard.pingInfo.direct ? " (direct)" : " (derp)")) : ""
                        textFormat: Text.PlainText
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption * 0.9
                        font.bold: true
                        color: (peerCard.pingInfo && peerCard.pingInfo.success) ? root.successColor : root.urgent
                      }
                    }
                  }

                  // Action Buttons Group (Right side: fixed width buttons aligned in columns)
                  RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Style.space(6)

                    // Copy IP Button
                    Rectangle {
                      implicitWidth: Style.space(68)
                      implicitHeight: Style.space(26)
                      radius: 4
                      color: (root.lastCopiedIp === peerCard.peerIp) ? Qt.rgba(root.successColor.r, root.successColor.g, root.successColor.b, 0.2) : (copyArea.containsMouse ? root.subtleBg : "transparent")
                      border.color: (root.lastCopiedIp === peerCard.peerIp) ? root.successColor : root.borderCol
                      border.width: 1

                      RowLayout {
                        anchors.centerIn: parent
                        spacing: Style.space(4)
                        Text {
                          text: (root.lastCopiedIp === peerCard.peerIp) ? root.glyphCheck : root.glyphCopy
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption * 0.9
                          color: (root.lastCopiedIp === peerCard.peerIp) ? root.successColor : root.foreground
                        }
                        Text {
                          text: (root.lastCopiedIp === peerCard.peerIp) ? "Copied" : "Copy"
                          textFormat: Text.PlainText
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption * 0.85
                          color: (root.lastCopiedIp === peerCard.peerIp) ? root.successColor : root.foreground
                        }
                      }

                      MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyIp(peerCard.peerIp, peerCard.peerHost)
                      }
                    }

                    // Ping Button (Online devices only)
                    Rectangle {
                      visible: peerCard.modelData.online === true
                      implicitWidth: Style.space(60)
                      implicitHeight: Style.space(26)
                      radius: 4
                      color: peerCard.isBeingPinged ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25) : (pingArea.containsMouse ? root.subtleBg : "transparent")
                      border.color: peerCard.isBeingPinged ? root.accent : root.borderCol
                      border.width: 1

                      RowLayout {
                        anchors.centerIn: parent
                        spacing: Style.space(4)
                        Text {
                          text: root.glyphPing
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption * 0.9
                          color: peerCard.isBeingPinged ? root.accent : root.foreground
                        }
                        Text {
                          text: peerCard.isBeingPinged ? "..." : "Ping"
                          textFormat: Text.PlainText
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption * 0.85
                          color: peerCard.isBeingPinged ? root.accent : root.foreground
                        }
                      }

                      MouseArea {
                        id: pingArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pingPeer(peerCard.peerIp)
                      }
                    }

                    // Spacer placeholder for offline devices to keep Copy button strictly aligned
                    Item {
                      visible: !peerCard.modelData.online
                      implicitWidth: Style.space(60)
                      implicitHeight: Style.space(26)
                    }
                  }
                }


                MouseArea {
                  id: peerCardArea
                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.NoButton
                }
              }
            }

            Rectangle {
              visible: root.filteredPeers().length === 0
              Layout.fillWidth: true
              implicitHeight: Style.space(48)
              color: "transparent"

              Text {
                anchors.centerIn: parent
                text: "No devices found matching filter"
                textFormat: Text.PlainText
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                color: root.dim
              }
            }
          }


          // 5. Footer Quick Actions
          Rectangle {
            width: parent.width
            implicitHeight: footerRow.implicitHeight + Style.space(12)
            color: root.cardBg
            radius: 8
            border.color: root.borderCol
            border.width: 1

            RowLayout {
              id: footerRow
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(8)

              // Tailscale Admin Console Web Link
              Rectangle {
                implicitWidth: adminRow.implicitWidth + Style.space(14)
                implicitHeight: Style.space(28)
                radius: 5
                color: adminArea.containsMouse ? root.subtleBg : "transparent"
                border.color: adminArea.containsMouse ? root.accent : root.borderCol
                border.width: 1

                RowLayout {
                  id: adminRow
                  anchors.centerIn: parent
                  spacing: Style.space(6)
                  Text {
                    text: root.glyphExternal
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.accent
                  }
                  Text {
                    text: "Admin Console"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: root.foreground
                  }
                }

                MouseArea {
                  id: adminArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Qt.openUrlExternally("https://login.tailscale.com/admin/machines")
                }
              }

              Item { Layout.fillWidth: true }

              // Connection Up/Down Status Text
              Text {
                text: root.connected ? "Tailscale Active" : "Tailscale Stopped"
                textFormat: Text.PlainText
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                color: root.connected ? root.successColor : root.dim
              }

              // Power / Toggle Button
              Rectangle {
                implicitWidth: powerRow.implicitWidth + Style.space(12)
                implicitHeight: Style.space(28)
                radius: 5
                color: root.connected ? Qt.rgba(root.urgent.r, root.urgent.g, root.urgent.b, 0.18) : Qt.rgba(root.successColor.r, root.successColor.g, root.successColor.b, 0.18)
                border.color: root.connected ? root.urgent : root.successColor
                border.width: 1

                RowLayout {
                  id: powerRow
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    text: root.connected ? "Disconnect" : "Connect"
                    textFormat: Text.PlainText
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: root.connected ? root.urgent : root.successColor
                  }
                }

                MouseArea {
                  id: powerArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.runHelper(["toggle"])
                }
              }
            }
          }
        }
      }
    }
  }
}
