import QtQuick
import Quickshell

Text {
  property string format: "hh:mm AP"
  property int interval: 1000 * 60
  property var date: new Date()
  text: date.toLocaleString(Qt.locale("C"), format)
  Timer {
    interval: parent.interval - date.getTime() % parent.interval
    running: true
    repeat: true
    onTriggered: parent.date = new Date()
  }
  //MouseArea {
  //  anchors.fill: parent
  //  onClicked: popup.visible = true;
  //}
}
