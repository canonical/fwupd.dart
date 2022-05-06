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
