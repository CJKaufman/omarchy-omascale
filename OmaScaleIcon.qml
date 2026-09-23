import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.space(12)
  property color color: Color.foreground
  property bool connected: true

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  // 24x24 reference box with light optical weight (matching 1px bar icons)
  // Dot diameter: 4.2 units, Gap: 4.8 units, Margin: 3.0 units
  // Centers: 5.1, 12.0, 18.9 (perfect 6.9 unit rhythm)
  readonly property real s: iconSize / 24.0
  readonly property real d: 4.2 * s
  readonly property real r: d / 2.0
  readonly property real c0: 3.0 * s
  readonly property real c1: 9.9 * s
  readonly property real c2: 16.8 * s

  opacity: root.connected ? 1.0 : 0.4

  // --- Solid Cross Nodes (Active Connected Mesh) ---
  // Center
  Rectangle {
    x: root.c1
    y: root.c1
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    antialiasing: true
  }

  // Top
  Rectangle {
    x: root.c1
    y: root.c0
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    antialiasing: true
  }

  // Bottom
  Rectangle {
    x: root.c1
    y: root.c2
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    antialiasing: true
  }

  // Left
  Rectangle {
    x: root.c0
    y: root.c1
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    antialiasing: true
  }

  // Right
  Rectangle {
    x: root.c2
    y: root.c1
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    antialiasing: true
  }

  // --- Corner Nodes (Subtle Unconnected Mesh Nodes) ---
  // Top-Left
  Rectangle {
    x: root.c0
    y: root.c0
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    opacity: 0.22
    antialiasing: true
  }

  // Top-Right
  Rectangle {
    x: root.c2
    y: root.c0
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    opacity: 0.22
    antialiasing: true
  }

  // Bottom-Left
  Rectangle {
    x: root.c0
    y: root.c2
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    opacity: 0.22
    antialiasing: true
  }

  // Bottom-Right
  Rectangle {
    x: root.c2
    y: root.c2
    width: root.d
    height: root.d
    radius: root.r
    color: root.color
    opacity: 0.22
    antialiasing: true
  }
}
