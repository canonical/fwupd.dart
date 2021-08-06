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
      properties['Percentage'] = DBusUint32(server.percentage);
      properties['Status'] = DBusUint32(server.status);
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.fwupd') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'Activate':
        //var id = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();

      case 'ClearResults':
        //var id = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();

      case 'Unlock':
        //var id = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();

      case 'Verify':
        //var id = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();

      case 'VerifyUpdate':
        //var id = (methodCall.values[0] as DBusString).value;
        return DBusMethodSuccessResponse();

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
  final int percentage;
  final List<Map<String, DBusValue>> plugins;
  final List<Map<String, DBusValue>> releases;
  final List<Map<String, DBusValue>> remotes;
  final int status;
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
      this.percentage = 0,
      this.plugins = const [],
      this.releases = const [],
      this.remotes = const [],
      this.status = 0,
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

  test('daemon status', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, status: 3, percentage: 42);
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.status, equals(FwupdStatus.decompressing));
    expect(client.percentage, equals(42));

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
        'Checksum': DBusString('CHECKSUM'),
        'Created': DBusUint64(1628138280),
        'DeviceId': DBusString('childId'),
        'Flags': DBusUint64(10),
        'Guid': DBusArray.string(['guid2']),
        'Icon': DBusArray.string(['computer']),
        'Name': DBusString('Child Device'),
        'ParentDeviceId': DBusString('parentId'),
        'Plugin': DBusString('plugin2'),
        'Summary': DBusString('A child plugin'),
        'Vendor': DBusString('VENDOR'),
        'VendorId': DBusString('VENDOR-ID'),
        'Version': DBusString('42'),
        'VersionFormat': DBusUint32(2)
      }
    ]);
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    var devices = await client.getDevices();
    expect(devices, hasLength(2));
    var device = devices[0];
    expect(device.checksum, isNull);
    expect(device.created, isNull);
    expect(device.deviceId, equals('parentId'));
    expect(device.flags, isEmpty);
    expect(device.guid, equals(['guid1a', 'guid1b']));
    expect(device.name, equals('Device 1'));
    expect(device.icon, equals([]));
    expect(device.parentDeviceId, isNull);
    expect(device.plugin, equals('plugin1'));
    expect(device.summary, isNull);
    expect(device.vendor, isNull);
    expect(device.vendorId, isNull);
    expect(device.version, isNull);
    expect(device.versionFormat, equals(FwupdVersionFormat.unknown));

    device = devices[1];
    expect(device.checksum, equals('CHECKSUM'));
    expect(device.created, equals(DateTime.utc(2021, 8, 5, 4, 38)));
    expect(device.deviceId, equals('childId'));
    expect(device.flags,
        equals({FwupdDeviceFlag.allowOnline, FwupdDeviceFlag.requireAc}));
    expect(device.guid, equals(['guid2']));
    expect(device.name, equals('Child Device'));
    expect(device.icon, equals(['computer']));
    expect(device.parentDeviceId, equals('parentId'));
    expect(device.plugin, equals('plugin2'));
    expect(device.summary, equals('A child plugin'));
    expect(device.vendor, equals('VENDOR'));
    expect(device.vendorId, equals('VENDOR-ID'));
    expect(device.version, equals('42'));
    expect(device.versionFormat, equals(FwupdVersionFormat.number));

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
          'Description': DBusString('DESCRIPTION1'),
          'Homepage': DBusString('http://example.com/1'),
          'License': DBusString('GPL-3.0'),
          'Name': DBusString('NAME1'),
          'Size': DBusUint64(123456),
          'Summary': DBusString('SUMMARY1'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('1.2')
        },
        {
          'AppstreamId': DBusString('com.example.Test'),
          'Checksum': DBusString('CHECKSUM'),
          'Created': DBusUint64(1585267200),
          'Description': DBusString('DESCRIPTION2'),
          'Filename': DBusString('test.cab'),
          'Homepage': DBusString('http://example.com/2'),
          'License': DBusString('GPL-3.0'),
          'Locations': DBusArray.string(['https://example.com/test.cab']),
          'Name': DBusString('NAME2'),
          'Protocol': DBusString('PROTOCOL'),
          'Size': DBusUint64(654321),
          'Summary': DBusString('SUMMARY2'),
          'TrustFlags': DBusUint64(4),
          'Urgency': DBusUint32(3),
          'Uri': DBusString('https://example.com/test.cab'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('3.4')
        }
      ]
    });
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    var upgrades = await client.getUpgrades('id1');
    expect(upgrades, hasLength(2));

    var upgrade = upgrades[0];
    expect(upgrade.appstreamId, isNull);
    expect(upgrade.checksum, isNull);
    expect(upgrade.created, isNull);
    expect(upgrade.description, equals('DESCRIPTION1'));
    expect(upgrade.filename, isNull);
    expect(upgrade.homepage, equals('http://example.com/1'));
    expect(upgrade.license, equals('GPL-3.0'));
    expect(upgrade.locations, isEmpty);
    expect(upgrade.name, equals('NAME1'));
    expect(upgrade.protocol, isNull);
    expect(upgrade.size, equals(123456));
    expect(upgrade.summary, equals('SUMMARY1'));
    expect(upgrade.flags, isEmpty);
    expect(upgrade.urgency, equals(FwupdReleaseUrgency.unknown));
    expect(upgrade.vendor, equals('VENDOR'));
    expect(upgrade.version, equals('1.2'));

    upgrade = upgrades[1];
    expect(upgrade.appstreamId, equals('com.example.Test'));
    expect(upgrade.checksum, equals('CHECKSUM'));
    expect(upgrade.created, equals(DateTime.utc(2020, 3, 27)));
    expect(upgrade.description, equals('DESCRIPTION2'));
    expect(upgrade.filename, equals('test.cab'));
    expect(upgrade.homepage, equals('http://example.com/2'));
    expect(upgrade.license, equals('GPL-3.0'));
    expect(upgrade.locations, equals(['https://example.com/test.cab']));
    expect(upgrade.name, equals('NAME2'));
    expect(upgrade.protocol, equals('PROTOCOL'));
    expect(upgrade.size, equals(654321));
    expect(upgrade.summary, equals('SUMMARY2'));
    expect(upgrade.flags, equals({FwupdReleaseFlag.isUpgrade}));
    expect(upgrade.urgency, equals(FwupdReleaseUrgency.high));
    expect(upgrade.vendor, equals('VENDOR'));
    expect(upgrade.version, equals('3.4'));

    await client.close();
  });
}
