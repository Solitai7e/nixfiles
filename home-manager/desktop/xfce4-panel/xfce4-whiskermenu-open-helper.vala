void main(string[] args) requires (args.length == 2)
                         requires (args[1].length > 0) {
  bool isPath = args[1].index_of_char('/') == 0;
  string uri = isPath ? "file://" + Uri.unescape_string(args[1]) : args[1];
  try {
    AppInfo.launch_default_for_uri(uri, null);
  } catch (Error error) {
    Notify.init("Whisker Menu");
    var notification = new Notify.Notification("Whisker Menu", error.message, null);
    notification.show();
  }
}
