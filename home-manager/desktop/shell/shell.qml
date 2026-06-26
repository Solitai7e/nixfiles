import Quickshell
import QtQuick

PanelWindow {
  anchors { bottom: true; left: true; right: true; }
  implicitHeight: 30

  Text {
    anchors.centerIn: parent
    text: "hello world"
  }
  Clock {
    anchors {
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
  }
}
