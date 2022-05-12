# Changelog

## 0.2.2

* Add missing errors and messages.
* Bump dbus to 0.7.3, use updated dbus APIs.
* Implemented FwupdClient.getApprovedFirmware/setApprovedFirmware/getBlockedFirmware/setBlockedFirmware().
* Implemented FwupdClient.getDetails().
* Fix typo in FwupdPlugin.toString().
* Document classes.
* Split code into smaller modules.

## 0.2.1

* Only list as supporting Linux.

## 0.2.0

* Add FwUpdClient.install().
* Add FwUpdClient.getDowngrades().
* Add FwupdClient.getReleases().
* Add daemon host properties and flags.
* Add device properties and flags.
* Add remote ID parsing for releases.
* Add device added/changed/removed signals.
* Make connect() a no-op when already connected.
* Use dbus 0.7.0.
* Improve method descriptions.
* Test improvements.

## 0.1.0

* Rename FwupdUpgrade to FwupdRelease.
* Add more fields and enum values.

## 0.0.2

* Add server status and percentage.
* Add device flags.
* Add docstrings.

## 0.0.1

* Initial release
