import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';

import 'fwupd_utils.dart';

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

enum FwupdUpdateState {
  unknown,
  pending,
  success,
  failed,
  reboot,
  failedTransient,
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

  factory FwupdDevice.fromProperties(Map<String, DBusValue> properties) {
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
        created: properties['Created']?.toDateTime(),
        deviceId: (properties['DeviceId'] as DBusString?)?.value ?? '',
        name: (properties['Name'] as DBusString?)?.value ?? '',
        flags: flags,
        guid: (properties['Guid'] as DBusArray?)?.mapString().toList() ?? [],
        icon: (properties['Icon'] as DBusArray?)?.mapString().toList() ?? [],
        modified: properties['Modified']?.toDateTime(),
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
