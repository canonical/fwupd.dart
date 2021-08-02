import 'dart:async';

import 'package:dbus/dbus.dart';

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
}
