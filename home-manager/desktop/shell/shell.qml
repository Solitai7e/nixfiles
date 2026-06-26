import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
  anchors { bottom: true; left: true; right: true; }
  implicitHeight: 30
  RowLayout {
    anchors.fill: parent
    WindowList {
      Layout.fillWidth: true
      Layout.fillHeight: true
    }
    Clock {
      Layout.fillHeight: true
    }
    Component.onCompleted: () => {
      for (const item of [this, ...this.children])
        print(
          [item.implicitWidth, item.implicitHeight],
          [item.width, item.height]);
    }
  }
}
