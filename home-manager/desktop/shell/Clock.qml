import QtQuick
import Quickshell

Text {
  property string format: "hh:mm AP"
  property int interval: 1000 * 60
  property var date: new Date()
  text: Qt.formatDateTime(date, format)
  verticalAlignment: Text.AlignVCenter
  Timer {
    interval: parent.interval - date.getTime() % parent.interval
    running: true
    onTriggered: () => {
      parent.date = new Date();
      start();
    }
  }
  //MouseArea {
  //  anchors.fill: parent
  //  onClicked: popup.visible = true;
  //}
}
