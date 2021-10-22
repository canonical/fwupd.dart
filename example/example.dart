import 'package:fwupd/fwupd.dart';

void main() async {
  var client = FwupdClient();
  await client.connect();
  print('Running fwupd ${client.daemonVersion}');
  print('Devices:');
  var devices = await client.getDevices();
  for (var device in devices) {
    print('${device.name}');
    try {
      var upgrades = await client.getUpgrades(device.deviceId);
      if (upgrades.isNotEmpty) {
        print('  Upgrades:');
        for (var upgrade in upgrades) {
          print('  ${upgrade.name} ${upgrade.version}');
        }
      }
    } on FwupdException {
      // No upgrades available.
    }
    try {
      var downgrades = await client.getDowngrades(device.deviceId);
      if (downgrades.isNotEmpty) {
        print('  Downgrades:');
        for (var downgrade in downgrades) {
          print('  ${downgrade.name} ${downgrade.version}');
        }
      }
    } on FwupdException {
      // No downgrades available.
    }
  }
  await client.close();
}
