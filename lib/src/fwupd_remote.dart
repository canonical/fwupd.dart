import 'package:dbus/dbus.dart';

import 'fwupd_utils.dart';

/// Kind of remote.
enum FwupdRemoteKind { unknown, download, local, directory }

/// Type of keyring used on a remote.
enum FwupdKeyringKind { unknown, none, gpg, pkcs7, jcat }

/// A source of metadata that provides firmware.
///
/// Remotes can be local (e.g. folders on a disk) or remote (e.g. downloaded over HTTP or IPFS).
class FwupdRemote {
  /// Age of the remote in seconds.
  final DateTime? age;

  /// Remote agreement in AppStream markup format.
  final String? agreement;

  /// True if firmware from the remote should be checked against the list of a approved checksums.
  final bool approvalRequired;

  /// True if reports should be automatically uploaded to this remote.
  final bool automaticReports;

  /// True if security reports should be automatically uploaded to this remote.
  final bool automaticSecurityReports;

  /// Remote checksum.
  final String? checksum;

  /// True if the remote is enabled and should be used.
  final bool enabled;

  /// Path and filename that the remote is using for a cache.
  final String? filenameCache;

  /// Path and filename that the remote is using for a signature cache.
  final String? filenameCacheSig;

  /// Path and filename of the remote itself, typically a `.conf` file.
  final String? filenameSource;

  /// Base URI for firmware.
  final String? firmwareBaseUri;

  /// Remote ID, e.g. `lvfs-testing`.
  final String id;

  /// Keyring kind of the remote.
  final FwupdKeyringKind keyringKind;

  /// Kind of the remote.
  final FwupdRemoteKind kind;

  /// URI for the remote metadata.
  final String? metadataUri;

  /// Password configured for the remote.
  final String? password;

  /// Priority of the remote, where bigger numbers are better.
  final int priority;

  /// Directory to store remote data.
  final String? remotesDir;

  /// URI for the remote reporting.
  final String? reportUri;

  /// URI for the security report.
  final String? securityReportUri;

  /// Remote title, e.g. `Linux Vendor Firmware Service`.
  final String? title;

  /// Username configured for the remote.
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

  factory FwupdRemote.fromProperties(Map<String, DBusValue> properties) {
    var kindValue = (properties['Type'] as DBusUint32?)?.value ?? 0;
    var kind = kindValue < FwupdRemoteKind.values.length
        ? FwupdRemoteKind.values[kindValue]
        : FwupdRemoteKind.unknown;
    var keyringValue = (properties['Keyring'] as DBusUint32?)?.value ?? 0;
    var keyring = keyringValue < FwupdKeyringKind.values.length
        ? FwupdKeyringKind.values[keyringValue]
        : FwupdKeyringKind.jcat;
    return FwupdRemote(
      age: properties['ModificationTime']?.toDateTime(),
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

  @override
  String toString() =>
      "FwupdRemote(age: $age, agreement: '$agreement', approvalRequired: $approvalRequired, automaticReports: $automaticReports, automaticSecurityReports: $automaticSecurityReports, checksum: '$checksum', enabled: $enabled, filenameCache: '$filenameCache', filenameCacheSig: '$filenameCacheSig', filenameSource: '$filenameSource', firmwareBaseUri: '$firmwareBaseUri', id: '$id', keyringKind: $keyringKind, kind: $kind, metadataUri: '$metadataUri', password: '${password?.replaceAll(RegExp('.'), '*')}', priority: $priority, remotesDir: '$remotesDir', reportUri: '$reportUri', securityReportUri: '$securityReportUri', title: '$title', username: '$username')";
}
