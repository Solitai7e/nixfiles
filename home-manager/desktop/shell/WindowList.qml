import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick.Controls

ListView {
  orientation: ListView.Horizontal
  model: ToplevelManager.toplevels
  delegate: ToolButton {
    id: button
    readonly property var client: modelData
    icon.source: client?.appId && Quickshell.iconPath(client.appId, false)
    text: client?.title ?? ""
    width: 200 // TODO: compute this from the available width (how???)
    contentItem: RowLayout {
      anchors {
        fill: parent
        leftMargin: 8
        rightMargin: 8
      }
      IconImage {
        source: button.icon.source
        implicitSize: title.implicitHeight
      }
      Label {
        id: title
        text: button.text
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
    onReleased: () => {
      if (client.activated) client.minimized = true;
      else                  client.activate();
    }
  }
}
