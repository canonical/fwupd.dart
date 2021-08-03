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
      case 'GetUpgrades':
        var deviceId = (methodCall.values[0] as DBusString).value;
        var upgrades = server.upgrades[deviceId];
        if (upgrades == null) {
          return DBusMethodErrorResponse('org.freedesktop.fwupd.Internal',
              [DBusString('invalid device id')]);
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              upgrades.map((e) => DBusDict.stringVariant(e)))
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
  final Map<String, List<Map<String, DBusValue>>> upgrades;

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
      this.remotes = const [],
      this.upgrades = const {}})
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

  test('get devices', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, devices: [
      {
        'DeviceId': DBusString('parentId'),
        'Guid': DBusArray.string(['guid1a', 'guid1b']),
        'Name': DBusString('Device 1'),
        'Plugin': DBusString('plugin1')
      },
      {
        'DeviceId': DBusString('childId'),
        'Guid': DBusArray.string(['guid2']),
        'Icon': DBusArray.string(['computer']),
        'Name': DBusString('Child Device'),
        'ParentDeviceId': DBusString('parentId'),
        'Plugin': DBusString('plugin2'),
        'Summary': DBusString('A child plugin')
      }
    ]);
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    var devices = await client.getDevices();
    expect(devices, hasLength(2));
    var device = devices[0];
    expect(device.deviceId, equals('parentId'));
    expect(device.guid, equals(['guid1a', 'guid1b']));
    expect(device.name, equals('Device 1'));
    expect(device.icon, equals([]));
    expect(device.parentDeviceId, isNull);
    expect(device.plugin, equals('plugin1'));
    expect(device.summary, isNull);
    device = devices[1];
    expect(device.deviceId, equals('childId'));
    expect(device.guid, equals(['guid2']));
    expect(device.name, equals('Child Device'));
    expect(device.icon, equals(['computer']));
    expect(device.parentDeviceId, equals('parentId'));
    expect(device.plugin, equals('plugin2'));
    expect(device.summary, equals('A child plugin'));

    await client.close();
  });

  test('get plugins', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, plugins: [
      {'Name': DBusString('plugin1')},
      {'Name': DBusString('plugin2')}
    ]);
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    var plugins = await client.getPlugins();
    expect(plugins, hasLength(2));
    var plugin = plugins[0];
    expect(plugin.name, equals('plugin1'));
    plugin = plugins[1];
    expect(plugin.name, equals('plugin2'));

    await client.close();
  });

  test('get upgrades', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, upgrades: {
      'id1': [
        {
          'Description': DBusString('DESCRIPTION'),
          'Homepage': DBusString('http://example.com'),
          'License': DBusString('GPL-3.0'),
          'Name': DBusString('NAME'),
          'Size': DBusUint64(123456),
          'Summary': DBusString('SUMMARY'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('1.2')
        }
      ]
    });
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    var upgrades = await client.getUpgrades('id1');
    expect(upgrades, hasLength(1));
    var upgrade = upgrades[0];
    expect(upgrade.description, equals('DESCRIPTION'));
    expect(upgrade.homepage, equals('http://example.com'));
    expect(upgrade.license, equals('GPL-3.0'));
    expect(upgrade.name, equals('NAME'));
    expect(upgrade.size, equals(123456));
    expect(upgrade.summary, equals('SUMMARY'));
    expect(upgrade.vendor, equals('VENDOR'));
    expect(upgrade.version, equals('1.2'));

    await client.close();
  });
}
