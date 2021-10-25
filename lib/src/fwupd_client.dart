import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';

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

@immutable
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

  @override
  int get hashCode => Object.hashAll([
        checksum,
        created,
        deviceId,
        Object.hashAll(flags),
        Object.hashAll(guid),
        Object.hashAll(icon),
        name,
        parentDeviceId,
        plugin,
        summary,
        vendor,
        vendorId,
        version,
        versionFormat
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is FwupdDevice &&
        other.checksum == checksum &&
        other.created == created &&
        other.deviceId == deviceId &&
        const SetEquality<FwupdDeviceFlag>().equals(other.flags, flags) &&
        const ListEquality<String>().equals(other.guid, guid) &&
        const ListEquality<String>().equals(other.icon, icon) &&
        other.name == name &&
        other.parentDeviceId == parentDeviceId &&
        other.plugin == plugin &&
        other.summary == summary &&
        other.vendor == vendor &&
        other.vendorId == vendorId &&
        other.version == version &&
        other.versionFormat == versionFormat;
  }
}

class FwupdPlugin {
  final String name;

  FwupdPlugin({
    required this.name,
  });

  @override
  String toString() => 'FwupdDevice(name: $name)';
}

@immutable
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

  @override
  int get hashCode => Object.hashAll([
        appstreamId,
        checksum,
        created,
        description,
        filename,
        homepage,
        installDuration,
        license,
        Object.hashAll(locations),
        name,
        protocol,
        remoteId,
        size,
        summary,
        Object.hashAll(flags),
        urgency,
        uri,
        vendor,
        version
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is FwupdRelease &&
        runtimeType == other.runtimeType &&
        appstreamId == other.appstreamId &&
        checksum == other.checksum &&
        created == other.created &&
        description == other.description &&
        filename == other.filename &&
        homepage == other.homepage &&
        installDuration == other.installDuration &&
        license == other.license &&
        const ListEquality<String>().equals(locations, other.locations) &&
        name == other.name &&
        protocol == other.protocol &&
        remoteId == other.remoteId &&
        size == other.size &&
        summary == other.summary &&
        const SetEquality<FwupdReleaseFlag>().equals(flags, other.flags) &&
        urgency == other.urgency &&
        uri == other.uri &&
        vendor == other.vendor &&
        version == other.version;
  }
}

enum FwupdRemoteKind { unknown, download, local, directory }
enum FwupdKeyringKind { unknown, none, gpg, pkcs7, jcat }

class FwupdRemote {
  final DateTime? age;
  final String? agreement;
  final bool approvalRequired;
  final bool automaticReports;
  final bool automaticSecurityReports;
  final String? checksum;
  final bool enabled;
  final String? filenameCache;
  final String? filenameCacheSig;
  final String? filenameSource;
  final String? firmwareBaseUri;
  final String id;
  final FwupdKeyringKind keyringKind;
  final FwupdRemoteKind kind;
  final String? metadataUri;
  final String? password;
  final int priority;
  final String? remotesDir;
  final String? reportUri;
  final String? securityReportUri;
  final String? title;
  final String? username;

  FwupdRemote(
      {this.age,
      this.agreement,
      this.approvalRequired = false,
      this.automaticReports = false,
      this.automaticSecurityReports = false,
      this.checksum,
      this.enabled = false,
      this.filenameCache,
      this.filenameCacheSig,
      this.filenameSource,
      this.firmwareBaseUri,
      required this.id,
      this.keyringKind = FwupdKeyringKind.jcat,
      this.kind = FwupdRemoteKind.unknown,
      this.metadataUri,
      this.password,
      this.priority = 0,
      this.remotesDir,
      this.reportUri,
      this.securityReportUri,
      this.title,
      this.username});

  @override
  String toString() =>
      "FwupdRemote(age: $age, agreement: '$agreement', approvalRequired: $approvalRequired, automaticReports: $automaticReports, automaticSecurityReports: $automaticSecurityReports, checksum: '$checksum', enabled: $enabled, filenameCache: '$filenameCache', filenameCacheSig: '$filenameCacheSig', filenameSource: '$filenameSource', firmwareBaseUri: '$firmwareBaseUri', id: '$id', keyringKind: $keyringKind, kind: $kind, metadataUri: '$metadataUri', password: '${password?.replaceAll(RegExp('.'), '*')}', priority: $priority, remotesDir: '$remotesDir', reportUri: '$reportUri', securityReportUri: '$securityReportUri', title: '$title', username: '$username')";
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

  Future<List<FwupdRelease>> getReleases(String deviceId) {
    return _getReleases('GetReleases', deviceId);
  }

  Future<List<FwupdRelease>> getDowngrades(String deviceId) {
    return _getReleases('GetDowngrades', deviceId);
  }

  Future<List<FwupdRelease>> getUpgrades(String deviceId) {
    return _getReleases('GetUpgrades', deviceId);
  }

  Future<List<FwupdRelease>> _getReleases(
      String method, String deviceId) async {
    DBusMethodResponse response;
    try {
      response = await _root.callMethod(
          'org.freedesktop.fwupd', method, [DBusString(deviceId)],
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

  // FIXME: 'GetDetails'

  // FIXME: 'GetHistory'

  // FIXME: 'GetHostSecurityAttrs'

  // FIXME: 'GetReportMetadata'

  // FIXME: 'Install'

  /// Verify firmware on a device.
  Future<void> verify(String id) async {
    await _root.callMethod('org.freedesktop.fwupd', 'Verify', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Update the cryptographic hash stored for a device.
  Future<void> verifyUpdate(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'VerifyUpdate', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Unlock a device to allow firmware access.
  Future<void> unlock(String id) async {
    await _root.callMethod('org.freedesktop.fwupd', 'Unlock', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Activate a firmware update on a device.
  Future<void> activate(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'Activate', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  // FIXME: 'GetResults'

  /// Gets the remotes configured in fwupd.
  Future<List<FwupdRemote>> getRemotes() async {
    var response = await _root.callMethod(
        'org.freedesktop.fwupd', 'GetRemotes', [],
        replySignature: DBusSignature('aa{sv}'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseRemote(properties))
        .toList();
  }

  // FIXME: 'GetApprovedFirmware'

  // FIXME: 'SetApprovedFirmware'

  // FIXME: 'GetBlockedFirmware'

  // FIXME: 'SetBlockedFirmware'

  // FIXME: 'SetFeatureFlags'

  /// Clear the results of an offline update.
  Future<void> clearResults(String id) async {
    await _root.callMethod(
        'org.freedesktop.fwupd', 'ClearResults', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  // FIXME: 'ModifyDevice'

  // FIXME: 'ModifyConfig'

  // FIXME: 'UpdateMetadata'

  // FIXME: 'ModifyRemote'

  // FIXME: 'SelfSign'

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
    var secs = (value as DBusUint64?)?.value ?? 0;
    if (secs <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
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

  FwupdRemote _parseRemote(Map<String, DBusValue> properties) {
    var kindValue = (properties['Type'] as DBusUint32?)?.value ?? 0;
    var kind = kindValue < FwupdRemoteKind.values.length
        ? FwupdRemoteKind.values[kindValue]
        : FwupdRemoteKind.unknown;
    var keyringValue = (properties['Keyring'] as DBusUint32?)?.value ?? 0;
    var keyring = keyringValue < FwupdKeyringKind.values.length
        ? FwupdKeyringKind.values[keyringValue]
        : FwupdKeyringKind.jcat;
    return FwupdRemote(
      age: _parseDateTime(properties['ModificationTime']),
      agreement: (properties['Agreement'] as DBusString?)?.value,
      approvalRequired:
          (properties['ApprovalRequired'] as DBusBoolean?)?.value ?? false,
      automaticReports:
          (properties['AutomaticReports'] as DBusBoolean?)?.value ?? false,
      automaticSecurityReports:
          (properties['AutomaticSecurityReports'] as DBusBoolean?)?.value ??
              false,
      checksum: (properties['Checksum'] as DBusString?)?.value,
      enabled: (properties['Enabled'] as DBusBoolean?)?.value ?? false,
      filenameCache: (properties['FilenameCache'] as DBusString?)?.value,
      filenameCacheSig: (properties['FilenameCacheSig'] as DBusString?)?.value,
      filenameSource: (properties['FilenameSource'] as DBusString?)?.value,
      firmwareBaseUri: (properties['FirmwareBaseUri'] as DBusString?)?.value,
      id: (properties['RemoteId'] as DBusString?)?.value ?? '',
      keyringKind: keyring,
      kind: kind,
      metadataUri: (properties['Uri'] as DBusString?)?.value,
      password: (properties['Password'] as DBusString?)?.value,
      priority: (properties['Priority'] as DBusInt32?)?.value ?? 0,
      remotesDir: (properties['RemotesDir'] as DBusString?)?.value,
      reportUri: (properties['ReportUri'] as DBusString?)?.value,
      securityReportUri:
          (properties['SecurityReportUri'] as DBusString?)?.value,
      title: (properties['Title'] as DBusString?)?.value,
      username: (properties['Username'] as DBusString?)?.value,
    );
  }
}
