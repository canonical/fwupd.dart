import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';

import 'fwupd_utils.dart';

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

  factory FwupdRelease.fromProperties(Map<String, DBusValue> properties) {
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
        created: properties['Created']?.toDateTime(),
        description: (properties['Description'] as DBusString?)?.value ?? '',
        filename: (properties['Filename'] as DBusString?)?.value,
        homepage: (properties['Homepage'] as DBusString?)?.value ?? '',
        installDuration:
            (properties['InstallDuration'] as DBusUint32?)?.value ?? 0,
        license: (properties['License'] as DBusString?)?.value ?? '',
        locations:
            (properties['Locations'] as DBusArray?)?.mapString().toList() ?? [],
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
