import 'package:dbus/dbus.dart';

import 'fwupd_utils.dart';

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
