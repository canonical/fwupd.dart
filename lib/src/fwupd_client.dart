import 'dart:async';

import 'package:dbus/dbus.dart';

class FwupdDevice {
  final String deviceId;
  final List<String> guid;
  final List<String> icon;
  final String name;
  final String? parentDeviceId;
  final String plugin;
  final String? summary;

  FwupdDevice(
      {required this.deviceId,
      this.guid = const [],
      this.icon = const [],
      required this.name,
      this.parentDeviceId,
      required this.plugin,
      this.summary});

  @override
  String toString() => "FwupdDevice(deviceId: $deviceId, name: '$name')";
}

class FwupdPlugin {
  final String name;

  FwupdPlugin({
    required this.name,
  });

  @override
  String toString() => 'FwupdDevice(name: $name)';
}

/// A client that connects to fwupd.
class FwupdClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus fwupd object.
  late final DBusRemoteObject _root;

  /// Cached property values.
  final _properties = <String, DBusValue>{};
  StreamSubscription? _propertiesChangedSubscription;
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  /// The version of the fwupd daemon.
  String get daemonVersion =>
      (_properties['DaemonVersion'] as DBusString).value;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  /// Creates a new fwupd client connected to the system D-Bus.
  FwupdClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root =
        DBusRemoteObject(_bus, 'org.freedesktop.fwupd', DBusObjectPath('/'));
  }

  /// Connects to the fwupd daemon.
  Future<void> connect() async {
    _propertiesChangedSubscription = _root.propertiesChanged.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.fwupd') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(await _root.getAllProperties('org.freedesktop.fwupd'));
  }

  /// Gets the devices being managed by fwupd.
  Future<List<FwupdDevice>> getDevices() async {
    var result = await _root.callMethod(
        'org.freedesktop.fwupd', 'GetDevices', [],
        replySignature: DBusSignature('aa{sv}'));
    return (result.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseDevice(properties))
        .toList();
  }

  /// Gets the plugins supported by fwupd.
  Future<List<FwupdPlugin>> getPlugins() async {
    var result = await _root.callMethod(
        'org.freedesktop.fwupd', 'GetPlugins', [],
        replySignature: DBusSignature('aa{sv}'));
    return (result.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parsePlugin(properties))
        .toList();
  }

  /// Terminates the connection to the fwupd daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_propertiesChangedSubscription != null) {
      await _propertiesChangedSubscription!.cancel();
      _propertiesChangedSubscription = null;
    }
    if (_closeBus) {
      await _bus.close();
    }
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  FwupdDevice _parseDevice(Map<String, DBusValue> properties) {
    return FwupdDevice(
        deviceId: (properties['DeviceId'] as DBusString?)?.value ?? '',
        name: (properties['Name'] as DBusString?)?.value ?? '',
        guid: (properties['Guid'] as DBusArray?)
                ?.children
                .map((value) => (value as DBusString).value)
                .toList() ??
            [],
        icon: (properties['Icon'] as DBusArray?)
                ?.children
                .map((value) => (value as DBusString).value)
                .toList() ??
            [],
        parentDeviceId: (properties['ParentDeviceId'] as DBusString?)?.value,
        plugin: (properties['Plugin'] as DBusString?)?.value ?? '',
        summary: (properties['Summary'] as DBusString?)?.value);
  }

  FwupdPlugin _parsePlugin(Map<String, DBusValue> properties) {
    return FwupdPlugin(name: (properties['Name'] as DBusString?)?.value ?? '');
  }
}
