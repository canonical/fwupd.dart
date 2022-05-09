import 'package:dbus/dbus.dart';

extension FwupdTimestamp on DBusValue {
  DateTime? toDateTime() {
    if (this is! DBusUint64) return null;
    var secs = (this as DBusUint64).value;
    if (secs <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
  }
}
