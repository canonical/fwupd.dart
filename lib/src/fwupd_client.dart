import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';

import 'fwupd_exceptions.dart';
import 'fwupd_device.dart';
import 'fwupd_plugin.dart';
import 'fwupd_release.dart';
import 'fwupd_remote.dart';

/// Daemon status.
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

/// Flags to set when performing the firmware update or install.
enum FwupdInstallFlag {
  offline,
  allowReinstall,
  allowOlder,
  force,
  noHistory,
  allowBranchSwitch,
  ignorePower,
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
  StreamSubscription? _deviceRequestSubscription;
  final _deviceRequestController = StreamController<FwupdDevice>.broadcast();

  /// The version of the fwupd daemon.
  String get daemonVersion => _properties['DaemonVersion']?.asString() ?? '';

  /// The product name for the host.
  String get hostProduct => _properties['HostProduct']?.asString() ?? '';

  /// The machine ID for the host.
  String get hostMachineId => _properties['HostMachineId']?.asString() ?? '';

  /// The security ID for the host.
  String get hostSecurityId => _properties['HostSecurityId']?.asString() ?? '';

  /// True if the daemon has been tainted with a 3rd party plugin.
  bool get tainted => _properties['Tainted']?.asBoolean() ?? false;

  /// True if the daemon is running on an interactive terminal.
  bool get interactive => _properties['Interactive']?.asBoolean() ?? false;

  /// The status of the fwupd daemon.
  FwupdStatus get status {
    var value = _properties['Status']?.asUint32();
    return value != null && value < FwupdStatus.values.length
        ? FwupdStatus.values[value]
        : FwupdStatus.unknown;
  }

  /// The percentage of the current job in process.
  int get percentage => _properties['Percentage']?.asUint32() ?? 0;

  /// Stream of devices as they are added.
  Stream<FwupdDevice> get deviceAdded => _deviceAddedController.stream;

  /// Stream of devices as they are changed.
  Stream<FwupdDevice> get deviceChanged => _deviceChangedController.stream;

  /// Stream of devices as they are removed.
  Stream<FwupdDevice> get deviceRemoved => _deviceRemovedController.stream;

  /// Stream of device requests.
  Stream<FwupdDevice> get deviceRequest => _deviceRequestController.stream;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  /// Creates a new fwupd client connected to the system D-Bus.
  FwupdClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus,
        name: 'org.freedesktop.fwupd', path: DBusObjectPath.root);
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
    _deviceAddedSubscription = deviceAdded.listen(
        (signal) => _deviceAdded(signal.values[0].asStringVariantDict()));

    var deviceChanged = DBusRemoteObjectSignalStream(
        object: _root,
        interface: 'org.freedesktop.fwupd',
        name: 'DeviceChanged');
    _deviceChangedSubscription = deviceChanged.listen(
        (signal) => _deviceChanged(signal.values[0].asStringVariantDict()));

    var deviceRemoved = DBusRemoteObjectSignalStream(
        object: _root,
        interface: 'org.freedesktop.fwupd',
        name: 'DeviceRemoved');
    _deviceRemovedSubscription = deviceRemoved.listen(
        (signal) => _deviceRemoved(signal.values[0].asStringVariantDict()));

    var deviceRequest = DBusRemoteObjectSignalStream(
        object: _root,
        interface: 'org.freedesktop.fwupd',
        name: 'DeviceRequest');
    _deviceRequestSubscription = deviceRequest.listen(
        (signal) => _deviceRequest(signal.values[0].asStringVariantDict()));
  }

  /// Gets the devices being managed by fwupd.
  Future<List<FwupdDevice>> getDevices() async {
    var response = await _callMethod('GetDevices', [],
        replySignature: DBusSignature('aa{sv}'));
    var devices = response.returnValues[0]
        .asArray()
        .map((child) => _parseDevice(child.asStringVariantDict()))
        .toList();
    _devices = {for (var device in devices) device.deviceId: device};
    return _devices.values.toList();
  }

  /// Gets the plugins supported by fwupd.
  Future<List<FwupdPlugin>> getPlugins() async {
    var response = await _callMethod('GetPlugins', [],
        replySignature: DBusSignature('aa{sv}'));
    return response.returnValues[0]
        .asArray()
        .map((child) => _parsePlugin(child.asStringVariantDict()))
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
    return response.returnValues[0]
        .asArray()
        .map((child) => _parseRelease(child.asStringVariantDict()))
        .toList();
  }

  /// Gets details about a firmware file.
  Future<Map<FwupdDevice, List<FwupdRelease>>> getDetails(
      ResourceHandle handle) async {
    var response = await _callMethod('GetDetails', [DBusUnixFd(handle)],
        replySignature: DBusSignature('aa{sv}'));
    return Map.fromEntries(response.returnValues[0].asArray().map((child) {
      var properties = child.asStringVariantDict();
      return MapEntry(
          _parseDevice(properties),
          properties['Release']
                  ?.asArray()
                  .map((child) => _parseRelease(child.asStringVariantDict()))
                  .toList() ??
              []);
    }));
  }

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
        replySignature: DBusSignature.empty);
  }

  /// Verify firmware on a device.
  Future<void> verify(String id) async {
    await _callMethod('Verify', [DBusString(id)],
        replySignature: DBusSignature.empty);
  }

  /// Update the cryptographic hash stored for a device.
  Future<void> verifyUpdate(String id) async {
    await _callMethod('VerifyUpdate', [DBusString(id)],
        replySignature: DBusSignature.empty);
  }

  /// Unlock a device to allow firmware access.
  Future<void> unlock(String id) async {
    await _callMethod('Unlock', [DBusString(id)],
        replySignature: DBusSignature.empty);
  }

  /// Activate a firmware update on a device.
  Future<void> activate(String id) async {
    await _callMethod('Activate', [DBusString(id)],
        replySignature: DBusSignature.empty);
  }

  // FIXME: 'GetResults'

  /// Gets the remotes configured in fwupd.
  Future<List<FwupdRemote>> getRemotes() async {
    var response = await _callMethod('GetRemotes', [],
        replySignature: DBusSignature('aa{sv}'));
    return response.returnValues[0]
        .asArray()
        .map((child) => _parseRemote(child.asStringVariantDict()))
        .toList();
  }

  /// Gets the list of approved firmware checksums
  Future<List<String>> getApprovedFirmware() async {
    var response = await _callMethod('GetApprovedFirmware', [],
        replySignature: DBusSignature('as'));
    return response.returnValues[0].asStringArray().toList();
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
    return response.returnValues[0].asStringArray().toList();
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
        replySignature: DBusSignature.empty);
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
    if (_deviceRequestSubscription != null) {
      await _deviceRequestSubscription!.cancel();
      _deviceRequestSubscription = null;
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

  Future<void> _deviceRequest(Map<String, DBusValue> properties) async {
    var device = _parseDevice(properties);
    _deviceRequestController.add(device);
  }

  FwupdDevice _parseDevice(Map<String, DBusValue> properties) {
    var flagsValue = properties['Flags']?.asUint64() ?? 0;
    var flags = <FwupdDeviceFlag>{};
    for (var i = 0; i < FwupdDeviceFlag.values.length; i++) {
      if (flagsValue & (1 << i) != 0) {
        flags.add(FwupdDeviceFlag.values[i]);
      }
    }
    var updateStateValue = properties['UpdateState']?.asUint32() ?? 0;
    var updateState = updateStateValue < FwupdUpdateState.values.length
        ? FwupdUpdateState.values[updateStateValue]
        : FwupdUpdateState.unknown;
    var versionFormatValue = properties['VersionFormat']?.asUint32() ?? 0;
    var versionFormat = versionFormatValue < FwupdVersionFormat.values.length
        ? FwupdVersionFormat.values[versionFormatValue]
        : FwupdVersionFormat.unknown;
    return FwupdDevice(
        checksum: properties['Checksum']?.asString(),
        created: _parseDateTime(properties['Created']),
        deviceId: properties['DeviceId']?.asString() ?? '',
        name: properties['Name']?.asString() ?? '',
        flags: flags,
        guid: properties['Guid']?.asStringArray().toList() ?? [],
        icon: properties['Icon']?.asStringArray().toList() ?? [],
        modified: _parseDateTime(properties['Modified']),
        parentDeviceId: properties['ParentDeviceId']?.asString(),
        plugin: properties['Plugin']?.asString() ?? '',
        protocol: properties['Protocol']?.asString(),
        summary: properties['Summary']?.asString(),
        updateError: properties['UpdateError']?.asString(),
        updateImage: properties['UpdateImage']?.asString(),
        updateMessage: properties['UpdateMessage']?.asString(),
        updateState: updateState,
        vendor: properties['Vendor']?.asString(),
        vendorId: properties['VendorId']?.asString(),
        version: properties['Version']?.asString(),
        versionBootloader: properties['VersionBootloader']?.asString(),
        versionFormat: versionFormat,
        versionLowest: properties['VersionLowest']?.asString());
  }

  DateTime? _parseDateTime(DBusValue? value) {
    var secs = value?.asUint64() ?? 0;
    if (secs <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
  }

  FwupdPlugin _parsePlugin(Map<String, DBusValue> properties) {
    return FwupdPlugin(name: properties['Name']?.asString() ?? '');
  }

  FwupdRelease _parseRelease(Map<String, DBusValue> properties) {
    var flagsValue = properties['TrustFlags']?.asUint64() ?? 0;
    var flags = <FwupdReleaseFlag>{};
    for (var i = 0; i < FwupdReleaseFlag.values.length; i++) {
      if (flagsValue & (1 << i) != 0) {
        flags.add(FwupdReleaseFlag.values[i]);
      }
    }
    var urgencyValue = properties['Urgency']?.asUint32() ?? 0;
    var urgency = urgencyValue < FwupdReleaseUrgency.values.length
        ? FwupdReleaseUrgency.values[urgencyValue]
        : FwupdReleaseUrgency.unknown;
    return FwupdRelease(
        appstreamId: properties['AppstreamId']?.asString(),
        checksum: properties['Checksum']?.asString(),
        created: _parseDateTime(properties['Created']),
        description: properties['Description']?.asString() ?? '',
        filename: properties['Filename']?.asString(),
        homepage: properties['Homepage']?.asString() ?? '',
        installDuration: properties['InstallDuration']?.asUint32() ?? 0,
        license: properties['License']?.asString() ?? '',
        locations: properties['Locations']?.asStringArray().toList() ?? [],
        name: properties['Name']?.asString() ?? '',
        protocol: properties['Protocol']?.asString(),
        remoteId: properties['RemoteId']?.asString(),
        size: properties['Size']?.asUint64() ?? 0,
        summary: properties['Summary']?.asString() ?? '',
        flags: flags,
        urgency: urgency,
        uri: properties['Uri']?.asString(),
        vendor: properties['Vendor']?.asString() ?? '',
        version: properties['Version']?.asString() ?? '');
  }

  FwupdRemote _parseRemote(Map<String, DBusValue> properties) {
    var kindValue = properties['Type']?.asUint32() ?? 0;
    var kind = kindValue < FwupdRemoteKind.values.length
        ? FwupdRemoteKind.values[kindValue]
        : FwupdRemoteKind.unknown;
    var keyringValue = properties['Keyring']?.asUint32() ?? 0;
    var keyring = keyringValue < FwupdKeyringKind.values.length
        ? FwupdKeyringKind.values[keyringValue]
        : FwupdKeyringKind.jcat;
    return FwupdRemote(
      age: _parseDateTime(properties['ModificationTime']),
      agreement: properties['Agreement']?.asString(),
      approvalRequired: properties['ApprovalRequired']?.asBoolean() ?? false,
      automaticReports: properties['AutomaticReports']?.asBoolean() ?? false,
      automaticSecurityReports:
          properties['AutomaticSecurityReports']?.asBoolean() ?? false,
      checksum: properties['Checksum']?.asString(),
      enabled: properties['Enabled']?.asBoolean() ?? false,
      filenameCache: properties['FilenameCache']?.asString(),
      filenameCacheSig: properties['FilenameCacheSig']?.asString(),
      filenameSource: properties['FilenameSource']?.asString(),
      firmwareBaseUri: properties['FirmwareBaseUri']?.asString(),
      id: properties['RemoteId']?.asString() ?? '',
      keyringKind: keyring,
      kind: kind,
      metadataUri: properties['Uri']?.asString(),
      password: properties['Password']?.asString(),
      priority: properties['Priority']?.asInt32() ?? 0,
      remotesDir: properties['RemotesDir']?.asString(),
      reportUri: properties['ReportUri']?.asString(),
      securityReportUri: properties['SecurityReportUri']?.asString(),
      title: properties['Title']?.asString(),
      username: properties['Username']?.asString(),
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
