import 'package:fwupd/fwupd.dart';

void main() async {
  var client = FwupdClient();
  await client.connect();
  var remotes = await client.getRemotes();
  for (var remote in remotes) {
    print('${remote.title}');
    print('  ID ${remote.id}');
    print('  Type ${remote.kind.toString().split('.').last}');
    print('  Enabled ${remote.enabled}');
    print('  Filename ${remote.filenameCache}');
  }
  await client.close();
}
