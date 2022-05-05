import 'dart:async';
import 'dart:io';

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

enum FwupdUpdateState {
  unknown,
  pending,
  success,
  failed,
  reboot,
  failedTransient,
}

enum FwupdInstallFlag {
  offline,
  allowReinstall,
  allowOlder,
  force,
  noHistory,
  allowBranchSwitch,
  ignorePower,
}

class FwupdException implements Exception {
  final dynamic message;

  const FwupdException([this.message]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Internal error
class FwupdInternalException extends FwupdException {
  const FwupdInternalException([dynamic message]) : super(message);
}

/// Installed newer firmware version
class FwupdVersionNewerException extends FwupdException {
  const FwupdVersionNewerException([dynamic message]) : super(message);
}

/// Installed same firmware version
class FwupdVersionSameException extends FwupdException {
  const FwupdVersionSameException([dynamic message]) : super(message);
}

/// Already set be be installed offline
class FwupdAlreadyPendingException extends FwupdException {
  const FwupdAlreadyPendingException([dynamic message]) : super(message);
}

/// Failed to get authentication
class FwupdAuthFailedException extends FwupdException {
  const FwupdAuthFailedException([dynamic message]) : super(message);
}

/// Failed to read from device
class FwupdReadException extends FwupdException {
  const FwupdReadException([dynamic message]) : super(message);
}

/// Failed to write to the device
class FwupdWriteException extends FwupdException {
  const FwupdWriteException([dynamic message]) : super(message);
}

/// Invalid file format
class FwupdInvalidFileException extends FwupdException {
  const FwupdInvalidFileException([dynamic message]) : super(message);
}

/// No matching device exists
class FwupdNotFoundException extends FwupdException {
  const FwupdNotFoundException([dynamic message]) : super(message);
}

/// Nothing to do
class FwupdNothingToDoException extends FwupdException {
  const FwupdNothingToDoException([dynamic message]) : super(message);
}

/// Action was not possible
class FwupdNotSupportedException extends FwupdException {
  const FwupdNotSupportedException([dynamic message]) : super(message);
}

/// Signature was invalid
class FwupdSignatureInvalidException extends FwupdException {
  const FwupdSignatureInvalidException([dynamic message]) : super(message);
}

/// AC power was required
class FwupdAcPowerRequiredException extends FwupdException {
  const FwupdAcPowerRequiredException([dynamic message]) : super(message);
}

/// Permission was denied
class FwupdPermissionDeniedException extends FwupdException {
  const FwupdPermissionDeniedException([dynamic message]) : super(message);
}

/// User has configured their system in a broken way
class FwupdBrokenSystemException extends FwupdException {
  const FwupdBrokenSystemException([dynamic message]) : super(message);
}

/// The system battery level is too low
class FwupdBatteryLevelTooLowException extends FwupdException {
  const FwupdBatteryLevelTooLowException([dynamic message]) : super(message);
}

/// User needs to do an action to complete the update
class FwupdNeedsUserActionException extends FwupdException {
  const FwupdNeedsUserActionException([dynamic message]) : super(message);
}

@immutable
class FwupdDevice {
  final String? checksum;
  final DateTime? created;
  final String deviceId;
  final Set<FwupdDeviceFlag> flags;
  final List<String> guid;
  final List<String> icon;
  final DateTime? modified;
  final String name;
  final String? parentDeviceId;
  final String plugin;
  final String? protocol;
  final String? summary;
  final FwupdUpdateState updateState;
  final String? vendor;
  final String? vendorId;
  final String? version;
  final String? versionBootloader;
  final FwupdVersionFormat versionFormat;
  final String? versionLowest;

  FwupdDevice(
      {this.checksum,
      this.created,
      required this.deviceId,
      this.flags = const {},
      this.guid = const [],
      this.icon = const [],
      this.modified,
      required this.name,
      this.parentDeviceId,
      required this.plugin,
      this.protocol,
      this.summary,
      this.updateState = FwupdUpdateState.unknown,
      this.vendor,
      this.vendorId,
      this.version,
      this.versionBootloader,
      this.versionFormat = FwupdVersionFormat.unknown,
      this.versionLowest});

  @override
  String toString() =>
      "FwupdDevice(checksum: $checksum, created: $created, deviceId: $deviceId, flags: $flags, guid: $guid, icon: $icon, modified: $modified, name: '$name', parentDeviceId: $parentDeviceId, plugin: $plugin, protocol: $protocol, summary: $summary, updateState: $updateState, vendor: $vendor, vendorId: $vendorId, version: $version, versionBootloader: $versionBootloader, versionFormat: $versionFormat, versionLowest: $versionLowest)";

  @override
  int get hashCode => Object.hashAll([
        checksum,
        created,
        deviceId,
        Object.hashAll(flags),
        Object.hashAll(guid),
        Object.hashAll(icon),
        modified,
        name,
        parentDeviceId,
        plugin,
        protocol,
        summary,
        updateState,
        vendor,
        vendorId,
        version,
        versionBootloader,
        versionFormat,
        versionLowest
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
        other.modified == modified &&
        other.name == name &&
        other.parentDeviceId == parentDeviceId &&
        other.plugin == plugin &&
        other.protocol == protocol &&
        other.summary == summary &&
        other.updateState == updateState &&
        other.vendor == vendor &&
        other.vendorId == vendorId &&
        other.version == version &&
        other.versionBootloader == versionBootloader &&
        other.versionFormat == versionFormat &&
        other.versionLowest == versionLowest;
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

  /// Devices.
  var _devices = <String, FwupdDevice>{};
  StreamSubscription? _deviceAddedSubscription;
  final _deviceAddedController = StreamController<FwupdDevice>.broadcast();
  StreamSubscription? _deviceChangedSubscription;
  final _deviceChangedController = StreamController<FwupdDevice>.broadcast();
  StreamSubscription? _deviceRemovedSubscription;
  final _deviceRemovedController = StreamController<FwupdDevice>.broadcast();

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

  /// Stream of devices as they are added.
  Stream<FwupdDevice> get deviceAdded => _deviceAddedController.stream;

  /// Stream of devices as they are changed.
  Stream<FwupdDevice> get deviceChanged => _deviceChangedController.stream;

  /// Stream of devices as they are removed.
  Stream<FwupdDevice> get deviceRemoved => _deviceRemovedController.stream;

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
    // Already connected
    if (_propertiesChangedSubscription != null) {
      return;
    }

    _propertiesChangedSubscription = _root.propertiesChanged.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.fwupd') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(await _root.getAllProperties('org.freedesktop.fwupd'));

    var deviceAdded = DBusRemoteObjectSignalStream(
        object: _root, interface: 'org.freedesktop.fwupd', name: 'DeviceAdded');
    _deviceAddedSubscription = deviceAdded.listen((signal) => _deviceAdded(
        (signal.values[0] as DBusDict).children.map((key, value) => MapEntry(
            (key as DBusString).value, (value as DBusVariant).value))));

    var deviceChanged = DBusRemoteObjectSignalStream(
        object: _root,
        interface: 'org.freedesktop.fwupd',
        name: 'DeviceChanged');
    _deviceChangedSubscription = deviceChanged.listen((signal) =>
        _deviceChanged((signal.values[0] as DBusDict).children.map(
            (key, value) => MapEntry(
                (key as DBusString).value, (value as DBusVariant).value))));

    var deviceRemoved = DBusRemoteObjectSignalStream(
        object: _root,
        interface: 'org.freedesktop.fwupd',
        name: 'DeviceRemoved');
    _deviceRemovedSubscription = deviceRemoved.listen((signal) =>
        _deviceRemoved((signal.values[0] as DBusDict).children.map(
            (key, value) => MapEntry(
                (key as DBusString).value, (value as DBusVariant).value))));
  }

  /// Gets the devices being managed by fwupd.
  Future<List<FwupdDevice>> getDevices() async {
    var response = await _callMethod('GetDevices', [],
        replySignature: DBusSignature('aa{sv}'));
    var devices = (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseDevice(properties))
        .toList();
    _devices = {for (var device in devices) device.deviceId: device};
    return _devices.values.toList();
  }

  /// Gets the plugins supported by fwupd.
  Future<List<FwupdPlugin>> getPlugins() async {
    var response = await _callMethod('GetPlugins', [],
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
    var response = await _callMethod(method, [DBusString(deviceId)],
        replySignature: DBusSignature('aa{sv}'));
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

  /// Schedule a firmware to be installed.
  Future<void> install(
    String id,
    ResourceHandle handle, {
    Set<FwupdInstallFlag> flags = const {},
  }) async {
    var options = DBusDict.stringVariant({
      'offline': DBusBoolean(flags.contains(FwupdInstallFlag.offline)),
      'allow-reinstall':
          DBusBoolean(flags.contains(FwupdInstallFlag.allowReinstall)),
      'allow-older': DBusBoolean(flags.contains(FwupdInstallFlag.allowOlder)),
      'force': DBusBoolean(flags.contains(FwupdInstallFlag.force)),
      'no-history': DBusBoolean(flags.contains(FwupdInstallFlag.noHistory)),
      'allow-branch-switch':
          DBusBoolean(flags.contains(FwupdInstallFlag.allowBranchSwitch)),
      'ignore-power': DBusBoolean(flags.contains(FwupdInstallFlag.ignorePower)),
    });
    await _callMethod('Install', [DBusString(id), DBusUnixFd(handle), options],
        replySignature: DBusSignature(''));
  }

  /// Verify firmware on a device.
  Future<void> verify(String id) async {
    await _callMethod('Verify', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Update the cryptographic hash stored for a device.
  Future<void> verifyUpdate(String id) async {
    await _callMethod('VerifyUpdate', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Unlock a device to allow firmware access.
  Future<void> unlock(String id) async {
    await _callMethod('Unlock', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Activate a firmware update on a device.
  Future<void> activate(String id) async {
    await _callMethod('Activate', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  // FIXME: 'GetResults'

  /// Gets the remotes configured in fwupd.
  Future<List<FwupdRemote>> getRemotes() async {
    var response = await _callMethod('GetRemotes', [],
        replySignature: DBusSignature('aa{sv}'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusDict).children.map((key, value) =>
            MapEntry((key as DBusString).value, (value as DBusVariant).value)))
        .map((properties) => _parseRemote(properties))
        .toList();
  }

  /// Gets the list of approved firmware checksums
  Future<List<String>> getApprovedFirmware() async {
    var response = await _callMethod('GetApprovedFirmware', [],
        replySignature: DBusSignature('as'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusString).value)
        .toList();
  }

  /// Sets the list of approved firmware checksums
  Future<void> setApprovedFirmware(List<String> checksums) {
    return _callMethod('SetApprovedFirmware', [DBusArray.string(checksums)],
        replySignature: DBusSignature(''));
  }

  /// Gets the list of blocked firmware checksums
  Future<List<String>> getBlockedFirmware() async {
    var response = await _callMethod('GetBlockedFirmware', [],
        replySignature: DBusSignature('as'));
    return (response.returnValues[0] as DBusArray)
        .children
        .map((child) => (child as DBusString).value)
        .toList();
  }

  /// Sets the list of blocked firmware checksums
  Future<void> setBlockedFirmware(List<String> checksums) {
    return _callMethod('SetBlockedFirmware', [DBusArray.string(checksums)],
        replySignature: DBusSignature(''));
  }

  // FIXME: 'SetFeatureFlags'

  /// Clear the results of an offline update.
  Future<void> clearResults(String id) async {
    await _callMethod('ClearResults', [DBusString(id)],
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
    if (_deviceAddedSubscription != null) {
      await _deviceAddedSubscription!.cancel();
      _deviceAddedSubscription = null;
    }
    if (_deviceChangedSubscription != null) {
      await _deviceChangedSubscription!.cancel();
      _deviceChangedSubscription = null;
    }
    if (_deviceRemovedSubscription != null) {
      await _deviceRemovedSubscription!.cancel();
      _deviceRemovedSubscription = null;
    }
    _devices.clear();
    if (_closeBus) {
      await _bus.close();
    }
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  Future<void> _deviceAdded(Map<String, DBusValue> properties) async {
    var device = _parseDevice(properties);
    _devices[device.deviceId] = device;
    _deviceAddedController.add(device);
  }

  Future<void> _deviceChanged(Map<String, DBusValue> properties) async {
    final device = _parseDevice(properties);
    if (device == _devices[device.deviceId]) {
      return;
    }
    _devices[device.deviceId] = device;
    _deviceChangedController.add(device);
  }

  Future<void> _deviceRemoved(Map<String, DBusValue> properties) async {
    var device = _parseDevice(properties);
    _devices.remove(device.deviceId);
    _deviceRemovedController.add(device);
  }

  FwupdDevice _parseDevice(Map<String, DBusValue> properties) {
    var flagsValue = (properties['Flags'] as DBusUint64?)?.value ?? 0;
    var flags = <FwupdDeviceFlag>{};
    for (var i = 0; i < FwupdDeviceFlag.values.length; i++) {
      if (flagsValue & (1 << i) != 0) {
        flags.add(FwupdDeviceFlag.values[i]);
      }
    }
    var updateStateValue =
        (properties['UpdateState'] as DBusUint32?)?.value ?? 0;
    var updateState = updateStateValue < FwupdUpdateState.values.length
        ? FwupdUpdateState.values[updateStateValue]
        : FwupdUpdateState.unknown;
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
        modified: _parseDateTime(properties['Modified']),
        parentDeviceId: (properties['ParentDeviceId'] as DBusString?)?.value,
        plugin: (properties['Plugin'] as DBusString?)?.value ?? '',
        protocol: (properties['Protocol'] as DBusString?)?.value,
        summary: (properties['Summary'] as DBusString?)?.value,
        updateState: updateState,
        vendor: (properties['Vendor'] as DBusString?)?.value,
        vendorId: (properties['VendorId'] as DBusString?)?.value,
        version: (properties['Version'] as DBusString?)?.value,
        versionBootloader:
            (properties['VersionBootloader'] as DBusString?)?.value,
        versionFormat: versionFormat,
        versionLowest: (properties['VersionLowest'] as DBusString?)?.value);
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

  Future<DBusMethodSuccessResponse> _callMethod(
      String name, Iterable<DBusValue> values,
      {DBusSignature? replySignature,
      bool noReplyExpected = false,
      bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    try {
      return await _root.callMethod(
        'org.freedesktop.fwupd',
        name,
        values,
        replySignature: replySignature,
        noReplyExpected: noReplyExpected,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization,
      );
    } on DBusMethodResponseException catch (e) {
      var errorResponse = e.response;
      var errorMessage = errorResponse.values.firstOrNull?.toNative();
      switch (errorResponse.errorName) {
        case 'org.freedesktop.fwupd.Internal':
          throw FwupdInternalException(errorMessage);
        case 'org.freedesktop.fwupd.VersionNewer':
          throw FwupdVersionNewerException(errorMessage);
        case 'org.freedesktop.fwupd.VersionSame':
          throw FwupdVersionSameException(errorMessage);
        case 'org.freedesktop.fwupd.AlreadyPending':
          throw FwupdAlreadyPendingException(errorMessage);
        case 'org.freedesktop.fwupd.AuthFailed':
          throw FwupdAuthFailedException(errorMessage);
        case 'org.freedesktop.fwupd.Read':
          throw FwupdReadException(errorMessage);
        case 'org.freedesktop.fwupd.Write':
          throw FwupdWriteException(errorMessage);
        case 'org.freedesktop.fwupd.InvalidFile':
          throw FwupdInvalidFileException(errorMessage);
        case 'org.freedesktop.fwupd.NotFound':
          throw FwupdNotFoundException(errorMessage);
        case 'org.freedesktop.fwupd.NothingToDo':
          throw FwupdNothingToDoException(errorMessage);
        case 'org.freedesktop.fwupd.NotSupported':
          throw FwupdNotSupportedException(errorMessage);
        case 'org.freedesktop.fwupd.SignatureInvalid':
          throw FwupdSignatureInvalidException(errorMessage);
        case 'org.freedesktop.fwupd.AcPowerRequired':
          throw FwupdAcPowerRequiredException(errorMessage);
        case 'org.freedesktop.fwupd.PermissionDenied':
          throw FwupdPermissionDeniedException(errorMessage);
        case 'org.freedesktop.fwupd.BrokenSystem':
          throw FwupdBrokenSystemException(errorMessage);
        case 'org.freedesktop.fwupd.BatteryLevelTooLow':
          throw FwupdBatteryLevelTooLowException(errorMessage);
        case 'org.freedesktop.fwupd.NeedsUserAction':
          throw FwupdNeedsUserActionException(errorMessage);
        default:
          rethrow;
      }
    }
  }
}
