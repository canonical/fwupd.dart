import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Flags used to represent device attributes.
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

/// Flags used when parsing version numbers.
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

/// Update state.
enum FwupdUpdateState {
  unknown,
  pending,
  success,
  failed,
  reboot,
  failedTransient,
}

/// A physical device on the host with optionally updatable firmware.
@immutable
class FwupdDevice {
  /// Device checksum.
  final String? checksum;

  /// When the device was created.
  final DateTime? created;

  /// Id for this device.
  final String deviceId;

  /// Device flags.
  final Set<FwupdDeviceFlag> flags;

  /// GUIDs used by this device.
  final List<String> guid;

  /// Icon names to use for the device.
  final List<String> icon;

  /// When the device was modified.
  final DateTime? modified;

  /// Device name.
  final String name;

  /// Id of the parent device.
  final String? parentDeviceId;

  /// The plugin that created the device.
  final String plugin;

  /// The protocol name that the device uses for updating.
  final String? protocol;

  /// One line device summary.
  final String? summary;

  /// Update error.
  final String? updateError;

  /// Update image URL.
  final String? updateImage;

  /// Update message.
  final String? updateMessage;

  /// Update state.
  final FwupdUpdateState updateState;

  // Device vendor.
  final String? vendor;

  /// Combined device vendor ID.
  final String? vendorId;

  /// Device version.
  final String? version;

  /// Version of the bootloader.
  final String? versionBootloader;

  /// Format that [version], [versionBootloader] and [versionLowest] is in.
  final FwupdVersionFormat versionFormat;

  /// Lowest version of firmware the device will accept.
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
      this.updateError,
      this.updateImage,
      this.updateMessage,
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
