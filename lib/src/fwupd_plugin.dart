import 'package:dbus/dbus.dart';

class FwupdPlugin {
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
