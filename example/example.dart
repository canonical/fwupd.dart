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
      var releases = await client.getUpgrades(device.deviceId);
      for (var release in releases) {
        print('  ${release.name}');
      }
    } on FwupdException {
      // No upgrades available.
    }
  }
  await client.close();
}
