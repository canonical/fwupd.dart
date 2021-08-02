import 'package:fwupd/fwupd.dart';

void main() async {
  var client = FwupdClient();
  await client.connect();
  print('Running fwupd ${client.daemonVersion}');
  await client.close();
}
