[![Pub Package](https://img.shields.io/pub/v/fwupd.svg)](https://pub.dev/packages/fwupd)
[![codecov](https://codecov.io/gh/canonical/fwupd.dart/branch/main/graph/badge.svg?token=0TTBEYP5BD)](https://codecov.io/gh/canonical/fwupd.dart)

Provides a client to connect to [fwupd](https://fwupd.org/) - the service that does firmware updates on Linux.

```dart
import 'package:fwupd/fwupd.dart';

var client = FwupdClient();
await client.connect();
print('Running fwupd ${client.daemonVersion}');
await client.close();
```

## Contributing to fwupd.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
