import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:fwupd/fwupd.dart';

class MockFwupdObject extends DBusObject {
  final MockFwupdServer server;

  MockFwupdObject(this.server) : super(DBusObjectPath('/'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.freedesktop.fwupd') {
      properties['DaemonVersion'] = DBusString(server.daemonVersion);
      properties['HostMachineId'] = DBusString(server.hostMachineId);
      properties['HostProduct'] = DBusString(server.hostProduct);
      properties['HostSecurityId'] = DBusString(server.hostSecurityId);
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.fwupd') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'GetApprovedFirmware':
        return DBusMethodSuccessResponse(
            [DBusArray.string(server.approvedFirmware)]);
      case 'GetBlockedFirmware':
        return DBusMethodSuccessResponse(
            [DBusArray.string(server.blockedFirmware)]);
      case 'GetDevices':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.devices.map((e) => DBusDict.stringVariant(e)))
        ]);
      case 'GetHistory':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.history.map((e) => DBusDict.stringVariant(e)))
        ]);
      case 'GetPlugins':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.plugins.map((e) => DBusDict.stringVariant(e)))
        ]);
      case 'GetReleases':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.releases.map((e) => DBusDict.stringVariant(e)))
        ]);
      case 'GetRemotes':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.remotes.map((e) => DBusDict.stringVariant(e)))
        ]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockFwupdServer extends DBusClient {
  late final MockFwupdObject _root;

  final List<String> approvedFirmware;
  final List<String> blockedFirmware;
  final String daemonVersion;
  final List<Map<String, DBusValue>> devices;
  final String hostMachineId;
  final String hostProduct;
  final String hostSecurityId;
  final List<Map<String, DBusValue>> history;
  final List<Map<String, DBusValue>> plugins;
  final List<Map<String, DBusValue>> releases;
  final List<Map<String, DBusValue>> remotes;

  MockFwupdServer(DBusAddress clientAddress,
      {this.approvedFirmware = const [],
      this.blockedFirmware = const [],
      this.daemonVersion = '',
      this.devices = const [],
      this.hostMachineId = '',
      this.hostProduct = '',
      this.hostSecurityId = '',
      this.history = const [],
      this.plugins = const [],
      this.releases = const [],
      this.remotes = const []})
      : super(clientAddress);

  Future<void> start() async {
    await requestName('org.freedesktop.fwupd');
    _root = MockFwupdObject(this);
    await registerObject(_root);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, daemonVersion: '1.2.3');
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.daemonVersion, equals('1.2.3'));

    await client.close();
  });
}
