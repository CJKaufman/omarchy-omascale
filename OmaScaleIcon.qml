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

  // Scale factor based on 16px reference
  readonly property real s: iconSize / 16.0
  readonly property real strokeW: Math.max(1.2, 1.4 * s)
  readonly property real dotR: Math.max(1.2, 1.5 * s)

  opacity: root.connected ? 1.0 : 0.45

  // 1. Omarchy Geometric Maze Corner Brackets
  // Top-Left Omarchy Bracket
  Rectangle {
    x: 1 * root.s
    y: 1 * root.s
    width: 6 * root.s
    height: root.strokeW
    color: root.color
  }
  Rectangle {
    x: 1 * root.s
    y: 1 * root.s
    width: root.strokeW
    height: 6 * root.s
    color: root.color
  }

  // Top-Right Omarchy Accent L
  Rectangle {
    x: 10 * root.s
    y: 1 * root.s
    width: 5 * root.s
    height: root.strokeW
    color: root.color
  }
  Rectangle {
    x: 15 * root.s - root.strokeW
    y: 1 * root.s
    width: root.strokeW
    height: 5 * root.s
    color: root.color
  }

  // Bottom-Right Omarchy Bracket
  Rectangle {
    x: 9 * root.s
    y: 15 * root.s - root.strokeW
    width: 6 * root.s
    height: root.strokeW
    color: root.color
  }
  Rectangle {
    x: 15 * root.s - root.strokeW
    y: 9 * root.s
    width: root.strokeW
    height: 6 * root.s
    color: root.color
  }

  // Bottom-Left Omarchy Accent L
  Rectangle {
    x: 1 * root.s
    y: 15 * root.s - root.strokeW
    width: 5 * root.s
    height: root.strokeW
    color: root.color
  }
  Rectangle {
    x: 1 * root.s
    y: 10 * root.s
    width: root.strokeW
    height: 5 * root.s
    color: root.color
  }

  // 2. Tailscale Mesh Network (Center Cross Nodes)
  // Connecting Lines
  Rectangle {
    x: 4.5 * root.s
    y: 8 * root.s - (root.strokeW / 2)
    width: 7 * root.s
    height: root.strokeW
    color: root.color
    opacity: 0.8
  }
  Rectangle {
    x: 8 * root.s - (root.strokeW / 2)
    y: 4.5 * root.s
    width: root.strokeW
    height: 7 * root.s
    color: root.color
    opacity: 0.8
  }

  // Mesh Dots
  // Center Dot
  Rectangle {
    x: 8 * root.s - root.dotR
    y: 8 * root.s - root.dotR
    width: root.dotR * 2
    height: root.dotR * 2
    radius: root.dotR
    color: root.color
  }

  // Top Dot
  Rectangle {
    x: 8 * root.s - (root.dotR * 0.9)
    y: 4.5 * root.s - (root.dotR * 0.9)
    width: root.dotR * 1.8
    height: root.dotR * 1.8
    radius: root.dotR * 0.9
    color: root.color
  }

  // Bottom Dot
  Rectangle {
    x: 8 * root.s - (root.dotR * 0.9)
    y: 11.5 * root.s - (root.dotR * 0.9)
    width: root.dotR * 1.8
    height: root.dotR * 1.8
    radius: root.dotR * 0.9
    color: root.color
  }

  // Left Dot
  Rectangle {
    x: 4.5 * root.s - (root.dotR * 0.9)
    y: 8 * root.s - (root.dotR * 0.9)
    width: root.dotR * 1.8
    height: root.dotR * 1.8
    radius: root.dotR * 0.9
    color: root.color
  }

  // Right Dot
  Rectangle {
    x: 11.5 * root.s - (root.dotR * 0.9)
    y: 8 * root.s - (root.dotR * 0.9)
    width: root.dotR * 1.8
    height: root.dotR * 1.8
    radius: root.dotR * 0.9
    color: root.color
  }
}
