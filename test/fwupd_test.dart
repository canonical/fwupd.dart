import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:fwupd/fwupd.dart';

class MockFwupdDevice {
  final String? checksum;
  final int? created;
  final String deviceId;
  final int? flags;
  final String name;
  final List<String>? guid;
  final List<String>? icon;
  final int? modified;
  final String? parentDeviceId;
  final String? plugin;
  final String? protocol;
  final String? summary;
  final int? updateState;
  final String? vendor;
  final String? vendorId;
  final String? version;
  final String? versionBootloader;
  final int? versionFormat;
  final String? versionLowest;

  var activated = false;
  var resultsCleared = false;
  var unlocked = false;
  var verified = false;
  var updateVerified = false;
  ResourceHandle? installed;
  var options = {};

  MockFwupdDevice(
      {this.checksum,
      this.created,
      required this.deviceId,
      this.flags,
      this.icon = const [],
      this.modified,
      this.name = '',
      this.guid = const [],
      this.parentDeviceId,
      this.plugin,
      this.protocol,
      this.summary,
      this.updateState,
      this.vendor,
      this.vendorId,
      this.version,
      this.versionBootloader,
      this.versionFormat,
      this.versionLowest});
}

class MockFwupdObject extends DBusObject {
  final MockFwupdServer server;

  MockFwupdObject(this.server) : super(DBusObjectPath('/'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.freedesktop.fwupd') {
      properties.addAll({
        'DaemonVersion': DBusString(server.daemonVersion),
        'HostMachineId': DBusString(server.hostMachineId),
        'HostProduct': DBusString(server.hostProduct),
        'HostSecurityId': DBusString(server.hostSecurityId),
        'Interactive': DBusBoolean(server.interactive),
        'Percentage': DBusUint32(server.percentage),
        'Status': DBusUint32(server.status),
        'Tainted': DBusBoolean(server.tainted)
      });
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.fwupd') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (server.errors.isNotEmpty) {
      return DBusMethodErrorResponse(
          server.errors.removeAt(0), [DBusString('test error')]);
    }

    switch (methodCall.name) {
      case 'Activate':
        var id = methodCall.values[0].asString();
        server._findDeviceById(id)!.activated = true;
        return DBusMethodSuccessResponse();

      case 'ClearResults':
        var id = methodCall.values[0].asString();
        server._findDeviceById(id)!.resultsCleared = true;
        return DBusMethodSuccessResponse();

      case 'Install':
        var id = methodCall.values[0].asString();
        var device = server._findDeviceById(id)!;
        device.installed = methodCall.values[1].asUnixFd();
        device.options = methodCall.values[2].toNative();
        return DBusMethodSuccessResponse();

      case 'Unlock':
        var id = methodCall.values[0].asString();
        server._findDeviceById(id)!.unlocked = true;
        return DBusMethodSuccessResponse();

      case 'Verify':
        var id = methodCall.values[0].asString();
        server._findDeviceById(id)!.verified = true;
        return DBusMethodSuccessResponse();

      case 'VerifyUpdate':
        var id = methodCall.values[0].asString();
        server._findDeviceById(id)!.updateVerified = true;
        return DBusMethodSuccessResponse();

      case 'GetApprovedFirmware':
        return DBusMethodSuccessResponse(
            [DBusArray.string(server.approvedFirmware)]);

      case 'SetApprovedFirmware':
        var checksums = methodCall.values[0].asStringArray();
        server.approvedFirmware
            .replaceRange(0, server.approvedFirmware.length, checksums);
        return DBusMethodSuccessResponse();

      case 'GetBlockedFirmware':
        return DBusMethodSuccessResponse(
            [DBusArray.string(server.blockedFirmware)]);

      case 'SetBlockedFirmware':
        var checksums = methodCall.values[0].asStringArray();
        server.blockedFirmware
            .replaceRange(0, server.blockedFirmware.length, checksums);
        return DBusMethodSuccessResponse();

      case 'GetDevices':
        var r = <DBusValue>[];
        for (var device in server.devices) {
          var d = <String, DBusValue>{
            'DeviceId': DBusString(device.deviceId),
            'Name': DBusString(device.name)
          };
          if (device.checksum != null) {
            d['Checksum'] = DBusString(device.checksum!);
          }
          if (device.created != null) {
            d['Created'] = DBusUint64(device.created!);
          }
          if (device.flags != null) {
            d['Flags'] = DBusUint64(device.flags!);
          }
          if (device.guid != null) {
            d['Guid'] = DBusArray.string(device.guid!);
          }
          if (device.icon != null) {
            d['Icon'] = DBusArray.string(device.icon!);
          }
          if (device.modified != null) {
            d['Modified'] = DBusUint64(device.modified!);
          }
          if (device.parentDeviceId != null) {
            d['ParentDeviceId'] = DBusString(device.parentDeviceId!);
          }
          if (device.plugin != null) {
            d['Plugin'] = DBusString(device.plugin!);
          }
          if (device.protocol != null) {
            d['Protocol'] = DBusString(device.protocol!);
          }
          if (device.summary != null) {
            d['Summary'] = DBusString(device.summary!);
          }
          if (device.updateState != null) {
            d['UpdateState'] = DBusUint32(device.updateState!);
          }
          if (device.vendor != null) {
            d['Vendor'] = DBusString(device.vendor!);
          }
          if (device.vendorId != null) {
            d['VendorId'] = DBusString(device.vendorId!);
          }
          if (device.version != null) {
            d['Version'] = DBusString(device.version!);
          }
          if (device.versionBootloader != null) {
            d['VersionBootloader'] = DBusString(device.versionBootloader!);
          }
          if (device.versionFormat != null) {
            d['VersionFormat'] = DBusUint32(device.versionFormat!);
          }
          if (device.versionLowest != null) {
            d['VersionLowest'] = DBusString(device.versionLowest!);
          }
          r.add(DBusDict.stringVariant(d));
        }
        return DBusMethodSuccessResponse(
            [DBusArray(DBusSignature('a{sv}'), r)]);

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
        var deviceId = methodCall.values[0].asString();
        var releases = server.releases[deviceId];
        if (releases == null) {
          return DBusMethodErrorResponse('org.freedesktop.fwupd.Internal',
              [DBusString('invalid device id')]);
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              releases.map((e) => DBusDict.stringVariant(e)))
        ]);

      case 'GetRemotes':
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.remotes.map((e) => DBusDict.stringVariant(e)))
        ]);

      case 'GetUpgrades':
        var deviceId = methodCall.values[0].asString();
        var upgrades = server.upgrades[deviceId];
        if (upgrades == null) {
          return DBusMethodErrorResponse('org.freedesktop.fwupd.Internal',
              [DBusString('invalid device id')]);
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              upgrades.map((e) => DBusDict.stringVariant(e)))
        ]);

      case 'GetDowngrades':
        var deviceId = methodCall.values[0].asString();
        var downgrades = server.downgrades[deviceId];
        if (downgrades == null) {
          return DBusMethodErrorResponse('org.freedesktop.fwupd.Internal',
              [DBusString('invalid device id')]);
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              downgrades.map((e) => DBusDict.stringVariant(e)))
        ]);

      case 'GetDetails':
        if (server.details.isEmpty || methodCall.values[0] is! DBusUnixFd) {
          return DBusMethodErrorResponse(
              'org.freedesktop.fwupd.Internal', [DBusString('invalid handle')]);
        }
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('a{sv}'),
              server.details.map((e) => DBusDict.stringVariant(e)))
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
  final List<MockFwupdDevice> devices;
  final String hostMachineId;
  final String hostProduct;
  final String hostSecurityId;
  final List<Map<String, DBusValue>> history;
  final bool interactive;
  final int percentage;
  final List<Map<String, DBusValue>> plugins;
  final Map<String, List<Map<String, DBusValue>>> releases;
  final List<Map<String, DBusValue>> remotes;
  final int status;
  final bool tainted;
  final Map<String, List<Map<String, DBusValue>>> upgrades;
  final Map<String, List<Map<String, DBusValue>>> downgrades;
  final List<String> errors;
  final List<Map<String, DBusValue>> details;

  MockFwupdServer(DBusAddress clientAddress,
      {this.approvedFirmware = const [],
      this.blockedFirmware = const [],
      this.daemonVersion = '',
      this.devices = const [],
      this.hostMachineId = '',
      this.hostProduct = '',
      this.hostSecurityId = '',
      this.history = const [],
      this.interactive = false,
      this.percentage = 0,
      this.plugins = const [],
      this.releases = const {},
      this.remotes = const [],
      this.status = 0,
      this.tainted = false,
      this.upgrades = const {},
      this.downgrades = const {},
      this.errors = const [],
      this.details = const []})
      : super(clientAddress);

  Future<void> start() async {
    await requestName('org.freedesktop.fwupd');
    _root = MockFwupdObject(this);
    await registerObject(_root);
  }

  MockFwupdDevice? _findDeviceById(String id) {
    for (var device in devices) {
      if (device.deviceId == id) {
        return device;
      }
    }
    return null;
  }

  Future<void> addDevice(Map<String, DBusValue> device) {
    return _root.emitSignal('org.freedesktop.fwupd', 'DeviceAdded',
        [DBusDict.stringVariant(device)]);
  }

  Future<void> changeDevice(Map<String, DBusValue> device) {
    return _root.emitSignal('org.freedesktop.fwupd', 'DeviceChanged',
        [DBusDict.stringVariant(device)]);
  }

  Future<void> removeDevice(Map<String, DBusValue> device) {
    return _root.emitSignal('org.freedesktop.fwupd', 'DeviceRemoved',
        [DBusDict.stringVariant(device)]);
  }

  Future<void> sendDeviceRequest(Map<String, DBusValue> device) {
    return _root.emitSignal('org.freedesktop.fwupd', 'DeviceRequest',
        [DBusDict.stringVariant(device)]);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, daemonVersion: '1.2.3');
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.daemonVersion, equals('1.2.3'));
  });

  test('daemon host details', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress,
        hostMachineId: 'MACHINE-ID',
        hostProduct: 'PRODUCT',
        hostSecurityId: 'SECURITY-ID');
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.hostMachineId, equals('MACHINE-ID'));
    expect(client.hostProduct, equals('PRODUCT'));
    expect(client.hostSecurityId, equals('SECURITY-ID'));
  });

  test('daemon interactive', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, interactive: true);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.interactive, isTrue);
  });

  test('daemon tainted', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, tainted: true);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.tainted, isTrue);
  });

  test('daemon status', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, status: 3, percentage: 42);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(client.status, equals(FwupdStatus.decompressing));
    expect(client.percentage, equals(42));
  });

  test('device signals', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    client.deviceAdded.listen(expectAsync1((device) {
      expect(device.deviceId, equals('ID'));
      expect(device.version, equals('1.0'));
    }));
    client.deviceChanged.listen(expectAsync1((device) {
      expect(device.deviceId, equals('ID'));
      expect(device.version, equals('1.1'));
    }));
    client.deviceRemoved.listen(expectAsync1((device) {
      expect(device.deviceId, equals('ID'));
      expect(device.version, equals('1.1'));
    }));
    client.deviceRequest.listen(expectAsync1((device) {
      expect(device.deviceId, equals('ID'));
      expect(device.version, equals('1.1'));
      expect(device.updateError, equals('An error occured'));
      expect(
          device.updateImage, equals('https://example.com/update_image.jpg'));
      expect(device.updateMessage, equals('Do some things with the device!'));
    }));

    await fwupd.addDevice(
        {'DeviceId': DBusString('ID'), 'Version': DBusString('1.0')});
    await fwupd.changeDevice(
        {'DeviceId': DBusString('ID'), 'Version': DBusString('1.0')}); // ignore
    await fwupd.changeDevice(
        {'DeviceId': DBusString('ID'), 'Version': DBusString('1.1')});
    await fwupd.sendDeviceRequest({
      'DeviceId': DBusString('ID'),
      'Version': DBusString('1.1'),
      'UpdateError': DBusString('An error occured'),
      'UpdateImage': DBusString('https://example.com/update_image.jpg'),
      'UpdateMessage': DBusString('Do some things with the device!'),
    });
    await fwupd.removeDevice(
        {'DeviceId': DBusString('ID'), 'Version': DBusString('1.1')});
  });

  test('get devices', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, devices: [
      MockFwupdDevice(
          deviceId: 'parentId',
          guid: ['guid1a', 'guid1b'],
          name: 'Device 1',
          plugin: 'plugin1'),
      MockFwupdDevice(
          checksum: 'CHECKSUM',
          created: 1628138280,
          deviceId: 'childId',
          flags: 10,
          guid: ['guid2'],
          icon: ['computer'],
          name: 'Child Device',
          modified: 1635254640,
          parentDeviceId: 'parentId',
          plugin: 'plugin2',
          protocol: 'protocol2',
          summary: 'A child plugin',
          updateState: 2,
          vendor: 'VENDOR',
          vendorId: 'VENDOR-ID',
          version: '42',
          versionBootloader: '53b',
          versionFormat: 2,
          versionLowest: '39')
    ]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var devices = await client.getDevices();
    expect(devices, hasLength(2));
    var device = devices[0];
    expect(device.checksum, isNull);
    expect(device.created, isNull);
    expect(device.deviceId, equals('parentId'));
    expect(device.flags, isEmpty);
    expect(device.guid, equals(['guid1a', 'guid1b']));
    expect(device.modified, isNull);
    expect(device.name, equals('Device 1'));
    expect(device.icon, equals([]));
    expect(device.parentDeviceId, isNull);
    expect(device.plugin, equals('plugin1'));
    expect(device.protocol, isNull);
    expect(device.summary, isNull);
    expect(device.updateState, equals(FwupdUpdateState.unknown));
    expect(device.vendor, isNull);
    expect(device.vendorId, isNull);
    expect(device.version, isNull);
    expect(device.versionBootloader, isNull);
    expect(device.versionFormat, equals(FwupdVersionFormat.unknown));
    expect(device.versionLowest, isNull);

    device = devices[1];
    expect(device.checksum, equals('CHECKSUM'));
    expect(device.created, equals(DateTime.utc(2021, 8, 5, 4, 38)));
    expect(device.deviceId, equals('childId'));
    expect(device.flags,
        equals({FwupdDeviceFlag.updatable, FwupdDeviceFlag.requireAc}));
    expect(device.guid, equals(['guid2']));
    expect(device.modified, equals(DateTime.utc(2021, 10, 26, 13, 24)));
    expect(device.name, equals('Child Device'));
    expect(device.icon, equals(['computer']));
    expect(device.parentDeviceId, equals('parentId'));
    expect(device.plugin, equals('plugin2'));
    expect(device.protocol, equals('protocol2'));
    expect(device.summary, equals('A child plugin'));
    expect(device.updateState, FwupdUpdateState.success);
    expect(device.vendor, equals('VENDOR'));
    expect(device.vendorId, equals('VENDOR-ID'));
    expect(device.version, equals('42'));
    expect(device.versionBootloader, equals('53b'));
    expect(device.versionFormat, equals(FwupdVersionFormat.number));
    expect(device.versionLowest, equals('39'));
  });

  test('get plugins', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, plugins: [
      {'Name': DBusString('plugin1')},
      {'Name': DBusString('plugin2')}
    ]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var plugins = await client.getPlugins();
    expect(plugins, hasLength(2));
    var plugin = plugins[0];
    expect(plugin.name, equals('plugin1'));
    plugin = plugins[1];
    expect(plugin.name, equals('plugin2'));
  });

  test('get releases', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var allUpgrades = {
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
          'InstallDuration': DBusUint32(3600),
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
    };

    var allDowngrades = {
      'id1': [
        {
          'Description': DBusString('DESCRIPTION1'),
          'Homepage': DBusString('http://example.com/1'),
          'License': DBusString('GPL-3.0'),
          'Name': DBusString('NAME1'),
          'Size': DBusUint64(123456),
          'Summary': DBusString('SUMMARY1'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('1.0')
        },
        {
          'AppstreamId': DBusString('com.example.Test'),
          'Checksum': DBusString('CHECKSUM'),
          'Created': DBusUint64(1585267200),
          'Description': DBusString('DESCRIPTION2'),
          'Filename': DBusString('test.cab'),
          'Homepage': DBusString('http://example.com/2'),
          'InstallDuration': DBusUint32(3600),
          'License': DBusString('GPL-3.0'),
          'Locations': DBusArray.string(['https://example.com/test.cab']),
          'Name': DBusString('NAME2'),
          'Protocol': DBusString('PROTOCOL'),
          'Size': DBusUint64(654321),
          'Summary': DBusString('SUMMARY2'),
          'TrustFlags': DBusUint64(8),
          'Urgency': DBusUint32(3),
          'Uri': DBusString('https://example.com/test.cab'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('3.2')
        }
      ]
    };

    var allReleases = {
      'id1': [
        ...allUpgrades['id1']!,
        {
          'Description': DBusString('CURRENT DESCRIPTION'),
          'Homepage': DBusString('http://example.com/current'),
          'License': DBusString('GPL-3.0'),
          'Name': DBusString('CURRENT NAME'),
          'Size': DBusUint64(789),
          'Summary': DBusString('CURRENT SUMMARY'),
          'Vendor': DBusString('VENDOR'),
          'Version': DBusString('2.0')
        },
        ...allDowngrades['id1']!,
      ],
    };

    var fwupd = MockFwupdServer(clientAddress,
        upgrades: allUpgrades,
        downgrades: allDowngrades,
        releases: allReleases);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var releases = await client.getReleases('id1');
    expect(releases, hasLength(5));

    var upgrades = await client.getUpgrades('id1');
    expect(upgrades, hasLength(2));

    var upgrade = upgrades[0];
    expect(releases[0], equals(upgrade));
    expect(upgrade.appstreamId, isNull);
    expect(upgrade.checksum, isNull);
    expect(upgrade.created, isNull);
    expect(upgrade.description, equals('DESCRIPTION1'));
    expect(upgrade.filename, isNull);
    expect(upgrade.homepage, equals('http://example.com/1'));
    expect(upgrade.installDuration, equals(0));
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
    expect(releases[1], equals(upgrade));
    expect(upgrade.appstreamId, equals('com.example.Test'));
    expect(upgrade.checksum, equals('CHECKSUM'));
    expect(upgrade.created, equals(DateTime.utc(2020, 3, 27)));
    expect(upgrade.description, equals('DESCRIPTION2'));
    expect(upgrade.filename, equals('test.cab'));
    expect(upgrade.homepage, equals('http://example.com/2'));
    expect(upgrade.installDuration, equals(3600));
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

    var downgrades = await client.getDowngrades('id1');
    expect(downgrades, hasLength(2));

    var downgrade = downgrades[0];
    expect(releases[3], equals(downgrade));
    expect(downgrade.appstreamId, isNull);
    expect(downgrade.checksum, isNull);
    expect(downgrade.created, isNull);
    expect(downgrade.description, equals('DESCRIPTION1'));
    expect(downgrade.filename, isNull);
    expect(downgrade.homepage, equals('http://example.com/1'));
    expect(downgrade.installDuration, equals(0));
    expect(downgrade.license, equals('GPL-3.0'));
    expect(downgrade.locations, isEmpty);
    expect(downgrade.name, equals('NAME1'));
    expect(downgrade.protocol, isNull);
    expect(downgrade.size, equals(123456));
    expect(downgrade.summary, equals('SUMMARY1'));
    expect(downgrade.flags, isEmpty);
    expect(downgrade.urgency, equals(FwupdReleaseUrgency.unknown));
    expect(downgrade.vendor, equals('VENDOR'));
    expect(downgrade.version, equals('1.0'));

    downgrade = downgrades[1];
    expect(releases[4], equals(downgrade));
    expect(downgrade.appstreamId, equals('com.example.Test'));
    expect(downgrade.checksum, equals('CHECKSUM'));
    expect(downgrade.created, equals(DateTime.utc(2020, 3, 27)));
    expect(downgrade.description, equals('DESCRIPTION2'));
    expect(downgrade.filename, equals('test.cab'));
    expect(downgrade.homepage, equals('http://example.com/2'));
    expect(downgrade.installDuration, equals(3600));
    expect(downgrade.license, equals('GPL-3.0'));
    expect(downgrade.locations, equals(['https://example.com/test.cab']));
    expect(downgrade.name, equals('NAME2'));
    expect(downgrade.protocol, equals('PROTOCOL'));
    expect(downgrade.size, equals(654321));
    expect(downgrade.summary, equals('SUMMARY2'));
    expect(downgrade.flags, equals({FwupdReleaseFlag.isDowngrade}));
    expect(downgrade.urgency, equals(FwupdReleaseUrgency.high));
    expect(downgrade.vendor, equals('VENDOR'));
    expect(downgrade.version, equals('3.2'));

    var current = releases[2];
    expect(current.description, equals('CURRENT DESCRIPTION'));
    expect(current.homepage, equals('http://example.com/current'));
    expect(current.license, equals('GPL-3.0'));
    expect(current.name, equals('CURRENT NAME'));
    expect(current.size, equals(789));
    expect(current.summary, equals('CURRENT SUMMARY'));
    expect(current.vendor, equals('VENDOR'));
    expect(current.version, equals('2.0'));
  });

  test('activate device', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(device.activated, isFalse);
    await client.activate('1234');
    expect(device.activated, isTrue);
  });

  test('clear device results', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(device.resultsCleared, isFalse);
    await client.clearResults('1234');
    expect(device.resultsCleared, isTrue);
  });

  test('unlock device', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(device.unlocked, isFalse);
    await client.unlock('1234');
    expect(device.unlocked, isTrue);
  });

  test('verify device', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(device.verified, isFalse);
    await client.verify('1234');
    expect(device.verified, isTrue);
  });

  test('verify device update', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    expect(device.updateVerified, isFalse);
    await client.verifyUpdate('1234');
    expect(device.updateVerified, isTrue);
  });

  test('get remotes', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, remotes: [
      {
        'ApprovalRequired': DBusBoolean(false),
        'AutomaticReports': DBusBoolean(false),
        'AutomaticSecurityReports': DBusBoolean(false),
        'Enabled': DBusBoolean(true),
        'FilenameCache':
            DBusString('/usr/share/installed-tests/fwupd/fwupd-tests.xml'),
        'FilenameSource': DBusString('/etc/fwupd/remotes.d/fwupd-tests.conf'),
        'Keyring': DBusUint32(1),
        'ModificationTime': DBusUint64(1624968886),
        'RemoteId': DBusString('fwupd-tests'),
        'RemotesDir': DBusString('/var/lib/fwupd/remotes.d'),
        'Title': DBusString('fwupd test suite'),
        'Type': DBusUint32(2),
      },
      {
        'Agreement': DBusString('<p>The LVFS is a free service...</p>'),
        'ApprovalRequired': DBusBoolean(false),
        'AutomaticReports': DBusBoolean(false),
        'AutomaticSecurityReports': DBusBoolean(false),
        'Enabled': DBusBoolean(false),
        'FilenameCache':
            DBusString('/var/lib/fwupd/remotes.d/lvfs-testing/metadata.xml.gz'),
        'FilenameSource': DBusString('/etc/fwupd/remotes.d/lvfs-testing.conf'),
        'Keyring': DBusUint32(4),
        'ModificationTime':
            DBusUint64(4294967296 * 4294967296), // 18446744073709551615
        'Priority': DBusInt32(1),
        'RemoteId': DBusString('lvfs-testing'),
        'RemotesDir': DBusString('/var/lib/fwupd/remotes.d'),
        'Title': DBusString('Linux Vendor Firmware Service (testing)'),
        'Type': DBusUint32(1),
        'Uri': DBusString(
            'https://cdn.fwupd.org/downloads/firmware-testing.xml.gz'),
      },
    ]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var remotes = await client.getRemotes();
    expect(remotes, hasLength(2));

    var remote = remotes[0];
    expect(remote.age, DateTime.utc(2021, 6, 29, 12, 14, 46));
    expect(remote.agreement, isNull);
    expect(remote.approvalRequired, isFalse);
    expect(remote.automaticReports, isFalse);
    expect(remote.automaticSecurityReports, isFalse);
    expect(remote.checksum, isNull);
    expect(remote.enabled, isTrue);
    expect(remote.filenameCache,
        equals('/usr/share/installed-tests/fwupd/fwupd-tests.xml'));
    expect(remote.filenameCacheSig, isNull);
    expect(
        remote.filenameSource, equals('/etc/fwupd/remotes.d/fwupd-tests.conf'));
    expect(remote.firmwareBaseUri, isNull);
    expect(remote.id, equals('fwupd-tests'));
    expect(remote.keyringKind, equals(FwupdKeyringKind.none));
    expect(remote.kind, equals(FwupdRemoteKind.local));
    expect(remote.metadataUri, isNull);
    expect(remote.password, isNull);
    expect(remote.priority, isZero);
    expect(remote.remotesDir, equals('/var/lib/fwupd/remotes.d'));
    expect(remote.reportUri, isNull);
    expect(remote.securityReportUri, isNull);
    expect(remote.title, equals('fwupd test suite'));
    expect(remote.username, isNull);

    remote = remotes[1];
    expect(remote.age, isNull);
    expect(remote.agreement, equals('<p>The LVFS is a free service...</p>'));
    expect(remote.approvalRequired, isFalse);
    expect(remote.automaticReports, isFalse);
    expect(remote.automaticSecurityReports, isFalse);
    expect(remote.checksum, isNull);
    expect(remote.enabled, isFalse);
    expect(remote.filenameCache,
        equals('/var/lib/fwupd/remotes.d/lvfs-testing/metadata.xml.gz'));
    expect(remote.filenameCacheSig, isNull);
    expect(remote.filenameSource,
        equals('/etc/fwupd/remotes.d/lvfs-testing.conf'));
    expect(remote.firmwareBaseUri, isNull);
    expect(remote.id, equals('lvfs-testing'));
    expect(remote.keyringKind, equals(FwupdKeyringKind.jcat));
    expect(remote.kind, equals(FwupdRemoteKind.download));
    expect(remote.metadataUri,
        equals('https://cdn.fwupd.org/downloads/firmware-testing.xml.gz'));
    expect(remote.password, isNull);
    expect(remote.priority, equals(1));
    expect(remote.remotesDir, equals('/var/lib/fwupd/remotes.d'));
    expect(remote.reportUri, isNull);
    expect(remote.securityReportUri, isNull);
    expect(remote.title, equals('Linux Vendor Firmware Service (testing)'));
    expect(remote.username, isNull);
  });

  test('data classes', () async {
    final release1 = FwupdRelease(
      description: 'DESCRIPTION1',
      homepage: 'http://example.com/1',
      license: 'GPL-3.0',
      name: 'NAME1',
      size: 123456,
      summary: 'SUMMARY1',
      vendor: 'VENDOR',
      version: '1.2',
    );

    final release2 = FwupdRelease(
      appstreamId: 'com.example.Test',
      checksum: 'CHECKSUM',
      created: DateTime.fromMillisecondsSinceEpoch(1585267200 * 1000),
      description: 'DESCRIPTION2',
      filename: 'test.cab',
      homepage: 'http://example.com/2',
      installDuration: 3600,
      license: 'GPL-3.0',
      locations: ['https://example.com/test.cab'],
      name: 'NAME2',
      protocol: 'PROTOCOL',
      size: 654321,
      summary: 'SUMMARY2',
      flags: {FwupdReleaseFlag.isUpgrade},
      urgency: FwupdReleaseUrgency.high,
      uri: 'https://example.com/test.cab',
      vendor: 'VENDOR',
      version: '3.4',
    );

    expect(release1, equals(release1));
    expect(release2, equals(release2));
    expect(release1, isNot(equals(release2)));

    final device1 = FwupdDevice(
      deviceId: 'parentId',
      guid: ['guid1a', 'guid1b'],
      name: 'Device 1',
      plugin: 'plugin1',
    );

    final device2 = FwupdDevice(
      checksum: 'CHECKSUM',
      created: DateTime.fromMillisecondsSinceEpoch(1628138280 * 1000),
      deviceId: 'childId',
      flags: {FwupdDeviceFlag.updatable, FwupdDeviceFlag.requireAc},
      guid: ['guid2'],
      icon: ['computer'],
      name: 'Child Device',
      parentDeviceId: 'parentId',
      plugin: 'plugin2',
      summary: 'A child plugin',
      vendor: 'VENDOR',
      vendorId: 'VENDOR-ID',
      version: '42',
      versionFormat: FwupdVersionFormat.number,
    );

    expect(device1, equals(device1));
    expect(device2, equals(device2));
    expect(device1, isNot(equals(device2)));
  });

  test('install', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var device = MockFwupdDevice(deviceId: '1234', name: 'Device 1');
    var fwupd = MockFwupdServer(clientAddress, devices: [device]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var handle = ResourceHandle.fromStdin(stdin);
    await client.install('1234', handle, flags: {
      FwupdInstallFlag.offline,
      FwupdInstallFlag.allowOlder,
      FwupdInstallFlag.force,
      FwupdInstallFlag.ignorePower,
    });
    expect(device.installed, isNotNull);
    expect(
        device.options,
        equals({
          'offline': true,
          'allow-reinstall': false,
          'allow-older': true,
          'force': true,
          'no-history': false,
          'allow-branch-switch': false,
          'ignore-power': true,
        }));
  });

  test('errors', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    const errors = {
      'org.freedesktop.fwupd.Internal': FwupdInternalException,
      'org.freedesktop.fwupd.VersionNewer': FwupdVersionNewerException,
      'org.freedesktop.fwupd.VersionSame': FwupdVersionSameException,
      'org.freedesktop.fwupd.AlreadyPending': FwupdAlreadyPendingException,
      'org.freedesktop.fwupd.AuthFailed': FwupdAuthFailedException,
      'org.freedesktop.fwupd.Read': FwupdReadException,
      'org.freedesktop.fwupd.Write': FwupdWriteException,
      'org.freedesktop.fwupd.InvalidFile': FwupdInvalidFileException,
      'org.freedesktop.fwupd.NotFound': FwupdNotFoundException,
      'org.freedesktop.fwupd.NothingToDo': FwupdNothingToDoException,
      'org.freedesktop.fwupd.NotSupported': FwupdNotSupportedException,
      'org.freedesktop.fwupd.SignatureInvalid': FwupdSignatureInvalidException,
      'org.freedesktop.fwupd.AcPowerRequired': FwupdAcPowerRequiredException,
      'org.freedesktop.fwupd.PermissionDenied': FwupdPermissionDeniedException,
      'org.freedesktop.fwupd.BrokenSystem': FwupdBrokenSystemException,
      'org.freedesktop.fwupd.BatteryLevelTooLow':
          FwupdBatteryLevelTooLowException,
      'org.freedesktop.fwupd.NeedsUserAction': FwupdNeedsUserActionException,
    };

    var fwupd = MockFwupdServer(clientAddress, errors: errors.keys.toList());
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    while (fwupd.errors.isNotEmpty) {
      await expectLater(
          () => client.getReleases(''),
          throwsA(isA<FwupdException>().having((e) => e.runtimeType, 'error',
              equals(errors[fwupd.errors.first]))));
    }
  });

  test('approved firmware', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, approvedFirmware: ['a1', 'a2']);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var approvedFirmware = await client.getApprovedFirmware();
    expect(approvedFirmware, ['a1', 'a2']);

    await client.setApprovedFirmware(['a3', 'a4']);
    expect(fwupd.approvedFirmware, ['a3', 'a4']);
  });

  test('blocked firmware', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, blockedFirmware: ['b1', 'b2']);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var blockedFirmware = await client.getBlockedFirmware();
    expect(blockedFirmware, ['b1', 'b2']);

    await client.setBlockedFirmware(['b3', 'b4']);
    expect(fwupd.blockedFirmware, ['b3', 'b4']);
  });

  test('get details', () async {
    var server = DBusServer();
    addTearDown(() async => await server.close());
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, details: [
      {
        'Name': DBusString('NAME'),
        'DeviceId': DBusString('ID'),
        'Vendor': DBusString('VENDOR'),
        'Release': DBusArray(DBusSignature('a{sv}'), [
          DBusDict.stringVariant(
              {'Name': DBusString('RELEASE'), 'Version': DBusString('1.0')}),
          DBusDict.stringVariant(
              {'Name': DBusString('RELEASE'), 'Version': DBusString('1.1')})
        ]),
      }
    ]);
    addTearDown(() async => await fwupd.close());
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    addTearDown(() async => await client.close());
    await client.connect();

    var handle = ResourceHandle.fromStdin(stdin);
    var details = await client.getDetails(handle);
    expect(details, hasLength(1));

    var device = details.keys.single;
    expect(device.name, 'NAME');
    expect(device.deviceId, 'ID');
    expect(device.vendor, 'VENDOR');

    var releases = details.values.single;
    expect(releases, hasLength(2));
    expect(releases[0].name, 'RELEASE');
    expect(releases[0].version, '1.0');
    expect(releases[1].name, 'RELEASE');
    expect(releases[1].version, '1.1');

    fwupd.details.clear();
    await expectLater(() => client.getDetails(handle),
        throwsA(isA<FwupdInternalException>()));
  });
}
