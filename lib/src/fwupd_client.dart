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
  scheduling,
  downloading,
  deviceRead,
  deviceErase,
  waitingForAuth,
  deviceBusy,
  shutdown
}

enum FwupdDeviceFlag {
  internal,
  updatable,
  onlyOffline,
  requireAc,
  locked,
  supported,
  needsBootloader,
  registered,
  needsReboot,
  reported,
  notified,
  useRuntimeVersion,
  installParentFirst,
  isBootloader,
  waitForReplug,
  ignoreValidation,
  trusted,
  needsShutdown,
  anotherWriteRequired,
  noAutoInstanceIds,
  needsActivation,
  ensureSemver,
  historical,
  onlySupported,
  willDisappear,
  canVerify,
  canVerifyImage,
  dualImage,
  selfRecovery,
  usableDuringUpdate,
  versionCheckRequired,
  installAllReleases,
  mdSetName,
  mdSetNameCategory,
  mdSetVerfmt,
  addCounterpartGuids,
  noGuidMatching,
  updatableHidden,
  skipsRestart,
  hasMultipleBranches,
  backupBeforeInstall,
  mdSetIcon,
  wildcardInstall,
  onlyVersionUpgrade,
  unreachable,
  affectsFde
}

enum FwupdVersionFormat {
  unknown,
  plain,
  number,
  pair,
  triplet,
  quad,
  bcd,
  intelMe,
  intelMe2,
  surfaceLegacy,
  surface,
  dellBios,
  hex
}

enum FwupdReleaseFlag {
  trustedPayload,
  trustedMetadata,
  isUpgrade,
  isDowngrade,
  blockedVersion,
  blockedApproval,
  isAlternateBranch
}

enum FwupdReleaseUrgency { unknown, low, medium, high, critical }

class FwupdException implements Exception {}

class FwupdNotSupportedException extends FwupdException {}

class FwupdNothingToDoException extends FwupdException {}

class FwupdDevice {
  final String? checksum;
  final DateTime? created;
  final String deviceId;
  final Set<FwupdDeviceFlag> flags;
  final List<String> guid;
  final List<String> icon;
  final String name;
  final String? parentDeviceId;
  final String plugin;
  final String? summary;
  final String? vendor;
  final String? vendorId;
  final String? version;
  final FwupdVersionFormat versionFormat;

  FwupdDevice(
      {this.checksum,
      this.created,
      required this.deviceId,
      this.flags = const {},
      this.guid = const [],
      this.icon = const [],
      required this.name,
      this.parentDeviceId,
      required this.plugin,
      this.summary,
      this.vendor,
      this.vendorId,
      this.version,
      this.versionFormat = FwupdVersionFormat.unknown});

  @override
  String toString() =>
      "FwupdDevice(checksum: $checksum, created: $created, deviceId: $deviceId, flags: $flags, guid: $guid, icon: $icon, name: '$name', parentDeviceId: $parentDeviceId, plugin: $plugin, summary: $summary, vendor: $vendor, vendorId: $vendorId, version: $version, versionFormat: $versionFormat)";
}

class FwupdPlugin {
  final String name;

  FwupdPlugin({
    required this.name,
  });

  @override
  String toString() => 'FwupdDevice(name: $name)';
}

class FwupdRelease {
  final String? appstreamId;
  final String? checksum;
  final DateTime? created;
  final String description;
  final String? filename;
  final String homepage;
  final int installDuration;
  final String license;
  final List<String> locations;
  final String name;
  final String? protocol;
  final String? remoteId;
  final int size;
  final String summary;
  final Set<FwupdReleaseFlag> flags;
  final FwupdReleaseUrgency urgency;
  final String? uri;
  final String vendor;
  final String version;

  FwupdRelease(
      {this.appstreamId,
      this.checksum,
      this.created,
      this.description = '',
      this.filename,
      this.homepage = '',
      this.installDuration = 0,
      this.license = '',
      this.locations = const [],
      required this.name,
      this.protocol,
      this.remoteId,
      this.size = 0,
      this.summary = '',
      this.flags = const {},
      this.urgency = FwupdReleaseUrgency.unknown,
      this.uri,
      this.vendor = '',
      this.version = ''});

  @override
  String toString() =>
      "FwupdRelease(appstreamId: $appstreamId, checksum: $checksum, created: $created, description: '$description', filename: $filename, homepage: $homepage, license: $license, locations: $locations, name: '$name', protocol: $protocol, remoteId: $remoteId, size: $size, flags: $flags, urgency: $urgency, uri: $uri, vendor: '$vendor', version: '$version')";
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
      (_properties['DaemonVersion'] as DBusString?)?.value ?? '';

  /// The product name for the host.
  String get hostProduct =>
      (_properties['HostProduct'] as DBusString?)?.value ?? '';

  /// The machine ID for the host.
  String get hostMachineId =>
      (_properties['HostMachineId'] as DBusString?)?.value ?? '';

  /// The security ID for the host.
  String get hostSecurityId =>
      (_properties['HostSecurityId'] as DBusString?)?.value ?? '';

  /// True if the daemon has been tainted with a 3rd party plugin.
  bool get tainted => (_properties['Tainted'] as DBusBoolean?)?.value ?? false;

  /// True if the daemon is running on an interactive terminal.
  bool get interactive =>
      (_properties['Interactive'] as DBusBoolean?)?.value ?? false;

  /// The status of the fwupd daemon.
  FwupdStatus get status {
    var value = (_properties['Status'] as DBusUint32?)?.value;
    return value != null && value < FwupdStatus.values.length
        ? FwupdStatus.values[value]
        : FwupdStatus.unknown;
  }

  /// The percentage of the current job in process.
  int get percentage => (_properties['Percentage'] as DBusUint32?)?.value ?? 0;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  /// Creates a new fwupd client connected to the system D-Bus.
  FwupdClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus,
        name: 'org.freedesktop.fwupd', path: DBusObjectPath('/'));
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

  Future<List<FwupdRelease>> getUpgrades(String deviceId) async {
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
        .map((properties) => _parseRelease(properties))
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
    var flagsValue = (properties['Flags'] as DBusUint64?)?.value ?? 0;
    var flags = <FwupdDeviceFlag>{};
    for (var i = 0; i < FwupdDeviceFlag.values.length; i++) {
      if (flagsValue & (1 << i) != 0) {
        flags.add(FwupdDeviceFlag.values[i]);
      }
    }
    var versionFormatValue =
        (properties['VersionFormat'] as DBusUint32?)?.value ?? 0;
    var versionFormat = versionFormatValue < FwupdVersionFormat.values.length
        ? FwupdVersionFormat.values[versionFormatValue]
        : FwupdVersionFormat.unknown;
    return FwupdDevice(
        checksum: (properties['Checksum'] as DBusString?)?.value,
        created: _parseDateTime(properties['Created']),
        deviceId: (properties['DeviceId'] as DBusString?)?.value ?? '',
        name: (properties['Name'] as DBusString?)?.value ?? '',
        flags: flags,
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
        summary: (properties['Summary'] as DBusString?)?.value,
        vendor: (properties['Vendor'] as DBusString?)?.value,
        vendorId: (properties['VendorId'] as DBusString?)?.value,
        version: (properties['Version'] as DBusString?)?.value,
        versionFormat: versionFormat);
  }

  DateTime? _parseDateTime(DBusValue? value) {
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(
        (value as DBusUint64).value * 1000,
        isUtc: true);
  }

  FwupdPlugin _parsePlugin(Map<String, DBusValue> properties) {
    return FwupdPlugin(name: (properties['Name'] as DBusString?)?.value ?? '');
  }

  FwupdRelease _parseRelease(Map<String, DBusValue> properties) {
    var flagsValue = (properties['TrustFlags'] as DBusUint64?)?.value ?? 0;
    var flags = <FwupdReleaseFlag>{};
    for (var i = 0; i < FwupdReleaseFlag.values.length; i++) {
      if (flagsValue & (1 << i) != 0) {
        flags.add(FwupdReleaseFlag.values[i]);
      }
    }
    var urgencyValue = (properties['Urgency'] as DBusUint32?)?.value ?? 0;
    var urgency = urgencyValue < FwupdReleaseUrgency.values.length
        ? FwupdReleaseUrgency.values[urgencyValue]
        : FwupdReleaseUrgency.unknown;
    return FwupdRelease(
        appstreamId: (properties['AppstreamId'] as DBusString?)?.value,
        checksum: (properties['Checksum'] as DBusString?)?.value,
        created: _parseDateTime(properties['Created']),
        description: (properties['Description'] as DBusString?)?.value ?? '',
        filename: (properties['Filename'] as DBusString?)?.value,
        homepage: (properties['Homepage'] as DBusString?)?.value ?? '',
        installDuration:
            (properties['InstallDuration'] as DBusUint32?)?.value ?? 0,
        license: (properties['License'] as DBusString?)?.value ?? '',
        locations: (properties['Locations'] as DBusArray?)
                ?.children
                .map((value) => (value as DBusString).value)
                .toList() ??
            [],
        name: (properties['Name'] as DBusString?)?.value ?? '',
        protocol: (properties['Protocol'] as DBusString?)?.value,
        remoteId: (properties['RemoteId'] as DBusString?)?.value,
        size: (properties['Size'] as DBusUint64?)?.value ?? 0,
        summary: (properties['Summary'] as DBusString?)?.value ?? '',
        flags: flags,
        urgency: urgency,
        uri: (properties['Uri'] as DBusString?)?.value,
        vendor: (properties['Vendor'] as DBusString?)?.value ?? '',
        version: (properties['Version'] as DBusString?)?.value ?? '');
  }
}
