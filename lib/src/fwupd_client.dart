import 'dart:async';

import 'package:dbus/dbus.dart';

enum FwupdStatus {
  unknown,
  idle,
  loading,
  decompressing,
  deviceRestart,
  deviceWrite,
  deviceVerify,
  scheduling
}

class FwupdException implements Exception {}

class FwupdNotSupportedException extends FwupdException {}

class FwupdNothingToDoException extends FwupdException {}

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

class FwupdUpgrade {
  final String description;
  final String homepage;
  final String license;
  final String name;
  final int size;
  final String summary;
  final String vendor;
  final String version;

  FwupdUpgrade(
      {this.description = '',
      this.homepage = '',
      this.license = '',
      required this.name,
      this.size = 0,
      this.summary = '',
      this.vendor = '',
      this.version = ''});

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

  /// The status of the fwupd daemon.
  FwupdStatus get status {
    var value = (_properties['Status'] as DBusUint32).value;
    return value < FwupdStatus.values.length
        ? FwupdStatus.values[value]
        : FwupdStatus.unknown;
  }

  /// The percentage of the current job in process.
  int get percentage => (_properties['Percentage'] as DBusUint32).value;

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
    var response = await _root.callMethod(
        'org.freedesktop.fwupd', 'GetDevices', [],
        replySignature: DBusSignature('aa{sv}'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseDevice(properties))
        .toList();
  }

  /// Gets the plugins supported by fwupd.
  Future<List<FwupdPlugin>> getPlugins() async {
    var response = await _root.callMethod(
        'org.freedesktop.fwupd', 'GetPlugins', [],
        replySignature: DBusSignature('aa{sv}'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parsePlugin(properties))
        .toList();
  }

  Future<List<FwupdUpgrade>> getUpgrades(String deviceId) async {
    DBusMethodResponse response;
    try {
      response = await _root.callMethod(
          'org.freedesktop.fwupd', 'GetUpgrades', [DBusString(deviceId)],
          replySignature: DBusSignature('aa{sv}'));
    } on DBusMethodResponseException catch (e) {
      var errorResponse = e.response;
      switch (errorResponse.errorName) {
        case 'org.freedesktop.fwupd.NotSupported':
          throw FwupdNotSupportedException();
        case 'org.freedesktop.fwupd.NothingToDo':
          throw FwupdNothingToDoException();
        default:
          rethrow;
      }
    }
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseUpgrade(properties))
        .toList();
  }

  Future<void> activate(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'Activate', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  Future<void> clearResults(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'ClearResults', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Unlock a device to allow firmware access.
  Future<void> unlock(String id) async {
    await _root.callMethod('org.freedesktop.fwupd', 'Unlock', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Verify firmware on a device.
  Future<void> verify(String id) async {
    await _root.callMethod('org.freedesktop.fwupd', 'Verify', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  Future<void> verifyUpdate(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'VerifyUpdate', [DBusString(id)],
        replySignature: DBusSignature(''));
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

  FwupdUpgrade _parseUpgrade(Map<String, DBusValue> properties) {
    return FwupdUpgrade(
        description: (properties['Description'] as DBusString?)?.value ?? '',
        homepage: (properties['Homepage'] as DBusString?)?.value ?? '',
        license: (properties['License'] as DBusString?)?.value ?? '',
        name: (properties['Name'] as DBusString?)?.value ?? '',
        size: (properties['Size'] as DBusUint64?)?.value ?? 0,
        summary: (properties['Summary'] as DBusString?)?.value ?? '',
        vendor: (properties['Vendor'] as DBusString?)?.value ?? '',
        version: (properties['Version'] as DBusString?)?.value ?? '');
  }
}
