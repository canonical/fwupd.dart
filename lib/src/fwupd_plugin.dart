import 'package:dbus/dbus.dart';

/// A plugin which is used by fwupd to enumerate and update devices.
class FwupdPlugin {
  /// Plugin name.
  final String name;

  FwupdPlugin({
    required this.name,
  });

  factory FwupdPlugin.fromProperties(Map<String, DBusValue> properties) {
    return FwupdPlugin(name: (properties['Name'] as DBusString?)?.value ?? '');
  }

  @override
  String toString() => 'FwupdDevice(name: $name)';
}
