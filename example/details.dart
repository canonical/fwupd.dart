import 'dart:io';

import 'package:fwupd/fwupd.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: details <file.cab>');
    exit(1);
  }

  var client = FwupdClient();
  await client.connect();

  for (final path in args) {
    var handle = ResourceHandle.fromFile(File(path).openSync());
    var details = await client.getDetails(handle);
    for (final detail in details.entries) {
      var device = detail.key;
      var releases = detail.value;
      for (final release in releases) {
        print('${release.name} ${release.version} (${device.name})');
      }
    }
  }

  await client.close();
}
