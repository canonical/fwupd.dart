import 'package:fwupd/fwupd.dart';

void main() async {
  var client = FwupdClient();
  await client.connect();
  print('Running fwupd ${client.daemonVersion}');
  print('Devices:');
  var devices = await client.getDevices();
  for (var device in devices) {
    print('  $device');
  }
  await client.close();
}
