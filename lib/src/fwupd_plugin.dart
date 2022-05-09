/// A plugin which is used by fwupd to enumerate and update devices.
class FwupdPlugin {
  /// Plugin name.
  final String name;

  FwupdPlugin({
    required this.name,
  });

  @override
  String toString() => 'FwupdPlugin(name: $name)';
}
