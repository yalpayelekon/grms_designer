// protocol/configuration_commands.dart
//
// A collection of configuration commands for the Helvar protocol
// These commands store scenes, manage device settings, and other configuration operations

import 'helvar_protocol.dart';

/// ConfigurationCommands provides a high-level interface for all configuration operations
/// available in the Helvar protocol.
class ConfigurationCommands {
  final HelvarProtocol _protocol;

  ConfigurationCommands(this._protocol);

  /// Store scene levels for a group
  ///
  /// [group] - The group number (1-16383)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [level] - The level percentage (0-100)
  /// [forceStore] - If true, overwrites 'ignore' values in the scene table
  void storeSceneGroup(int group, int block, int scene, int level,
      {bool forceStore = true}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }

    final force = forceStore ? 1 : 0;
    final message = '>V:1,C:201,G:$group,O:$force,B:$block,S:$scene,L:$level#';
    _protocol.sendMessageWithAck(message);
  }

  /// Store scene levels for a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [level] - The level percentage (0-100)
  /// [forceStore] - If true, overwrites 'ignore' values in the scene table
  void storeSceneDevice(int cluster, int router, int subnet, int device,
      int block, int scene, int level,
      {bool forceStore = true}) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    if (router < 1 || router > 254) {
      throw ArgumentError('Router must be between 1 and 254');
    }
    if (subnet < 1 || subnet > 4) {
      throw ArgumentError('Subnet must be between 1 and 4');
    }
    if (device < 1 || device > 255) {
      throw ArgumentError('Device must be between 1 and 255');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }

    final force = forceStore ? 1 : 0;
    final message =
        '>V:1,C:202,@$cluster.$router.$subnet.$device,O:$force,B:$block,S:$scene,L:$level#';
    _protocol.sendMessageWithAck(message);
  }

  /// Store current levels of devices in a group as a scene
  ///
  /// [group] - The group number (1-16383)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [forceStore] - If true, overwrites 'ignore' values in the scene table
  void storeAsSceneGroup(int group, int block, int scene,
      {bool forceStore = true}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }

    final force = forceStore ? 1 : 0;
    final message = '>V:1,C:203,G:$group,O:$force,B:$block,S:$scene#';
    _protocol.sendMessageWithAck(message);
  }

  /// Store current level of a device as a scene
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [forceStore] - If true, overwrites 'ignore' values in the scene table
  void storeAsSceneDevice(
      int cluster, int router, int subnet, int device, int block, int scene,
      {bool forceStore = true}) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    if (router < 1 || router > 254) {
      throw ArgumentError('Router must be between 1 and 254');
    }
    if (subnet < 1 || subnet > 4) {
      throw ArgumentError('Subnet must be between 1 and 4');
    }
    if (device < 1 || device > 255) {
      throw ArgumentError('Device must be between 1 and 255');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }

    final force = forceStore ? 1 : 0;
    final message =
        '>V:1,C:204,@$cluster.$router.$subnet.$device,O:$force,B:$block,S:$scene#';
    _protocol.sendMessageWithAck(message);
  }

  /// Discovers Helvar routers on the network
  ///
  /// This sends a broadcast message to find all routers and their workgroups
  /// Returns via the protocol's message response handler
  void discoverRouters() {
    _protocol.discoverRouters();
  }
}
