import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:fwupd/fwupd.dart';

class MockFwupdObject extends DBusObject {
  final MockFwupdServer server;

  MockFwupdObject(this.server) : super(DBusObjectPath('/'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.freedesktop.fwupd') {
      properties['DaemonVersion'] = DBusString(server.daemonVersion);
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.fwupd') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockFwupdServer extends DBusClient {
  late final MockFwupdObject _root;

  final String daemonVersion;

  MockFwupdServer(DBusAddress clientAddress, {this.daemonVersion = ''})
      : super(clientAddress);

  Future<void> start() async {
    await requestName('org.freedesktop.fwupd');
    _root = MockFwupdObject(this);
    await registerObject(_root);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var fwupd = MockFwupdServer(clientAddress, daemonVersion: '1.2.3');
    await fwupd.start();

    var client = FwupdClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.daemonVersion, equals('1.2.3'));

    await client.close();
  });
}
