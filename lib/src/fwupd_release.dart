import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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

/// A firmware release with a specific version.
///
/// Devices can have more than one release, and the releases are typically ordered by their version.
@immutable
class FwupdRelease {
  /// Appstream ID for this release.
  final String? appstreamId;

  /// Release checksum.
  final String? checksum;

  /// When the update was created.
  final DateTime? created;

  /// Update description in AppStream markup format.
  final String description;

  /// Update filename.
  final String? filename;

  /// Update homepage URL
  final String homepage;

  /// Time estimate for firmware installation in seconds.
  final int installDuration;

  /// Update license.
  final String license;

  /// Update URI, i.e. where you can download the firmware from.
  ///
  /// Typically the first URI will be the main HTTP mirror, but all URIs may not be valid HTTP URIs. For example, "ipns://QmSrPmba" is valid here.
  final List<String> locations;

  /// Update name.
  final String name;

  /// Update protocol, e.g. `org.usb.dfu`
  final String? protocol;

  /// Remote ID that can be used for downloading.
  final String? remoteId;

  /// Update size in bytes.
  final int size;

  /// One line update summary.
  final String summary;

  /// Release flags.
  final Set<FwupdReleaseFlag> flags;

  /// Release urgency.
  final FwupdReleaseUrgency urgency;

  /// Default update URI.
  /// Deprecated, use [locations] instead.
  final String? uri;

  /// Vendor name, e.g. `Hughski Limited`.
  final String vendor;

  /// Update version, e.g. `1.2.4`.
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
