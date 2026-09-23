import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.space(16)
  property color color: Color.foreground
  property bool connected: true

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  // 24x24 reference grid (official Tailscale mark)
  // 3x3 grid: dots are 6 units diameter (radius 3), 3 units gap
  readonly property real s: iconSize / 24.0
  readonly property real d: 6.0 * s
  readonly property real r: 3.0 * s
  readonly property real borderWidth: Math.max(1.0, 1.2 * s)

  opacity: root.connected ? 1.0 : 0.45

  // --- Solid Cross Nodes (Active Connected Mesh) ---
  // Center
  Rectangle {
    x: 9.0 * root.s
    y: 9.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
  }

  // Top
  Rectangle {
    x: 9.0 * root.s
    y: 0.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
  }

  // Bottom
  Rectangle {
    x: 9.0 * root.s
    y: 18.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
  }

  // Left
  Rectangle {
    x: 0.0 * root.s
    y: 9.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
  }

  // Right
  Rectangle {
    x: 18.0 * root.s
    y: 9.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
  }

  // --- Corner Nodes (Official Tailscale Rings) ---
  // Top-Left
  Rectangle {
    x: 0.0 * root.s
    y: 0.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: "transparent"
    border.color: root.color
    border.width: root.borderWidth
    opacity: 0.55
  }

  // Top-Right
  Rectangle {
    x: 18.0 * root.s
    y: 0.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: "transparent"
    border.color: root.color
    border.width: root.borderWidth
    opacity: 0.55
  }

  // Bottom-Left
  Rectangle {
    x: 0.0 * root.s
    y: 18.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: "transparent"
    border.color: root.color
    border.width: root.borderWidth
    opacity: 0.55
  }

  // Bottom-Right
  Rectangle {
    x: 18.0 * root.s
    y: 18.0 * root.s
    width: root.d
    height: root.d
    radius: root.r
    color: "transparent"
    border.color: root.color
    border.width: root.borderWidth
    opacity: 0.55
  }
}
