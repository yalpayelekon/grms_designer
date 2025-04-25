// protocol/control_commands.dart
//
// A collection of control commands for the Helvar protocol
// These commands control lighting levels, scenes, proportions, and other control operations

import 'helvar_protocol.dart';

/// ControlCommands provides a high-level interface for all lighting control operations
/// available in the Helvar protocol.
class ControlCommands {
  final HelvarProtocol _protocol;

  ControlCommands(this._protocol);

  /// Recall a scene across a group
  ///
  /// [group] - The group number (1-16383)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  /// [constantLight] - Whether to use constant light mode
  void recallSceneGroup(int group, int block, int scene, int fadeTime,
      {bool constantLight = false}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final cl = constantLight ? 1 : 0;
    final message = '>V:1,C:11,G:$group,K:$cl,B:$block,S:$scene,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Recall a scene to a specific device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [block] - The scene block (1-8)
  /// [scene] - The scene number (1-16)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void recallSceneDevice(int cluster, int router, int subnet, int device,
      int block, int scene, int fadeTime) {
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
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message =
        '>V:1,C:12,@$cluster.$router.$subnet.$device,B:$block,S:$scene,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Set a direct level to a group
  ///
  /// [group] - The group number (1-16383)
  /// [level] - The level percentage (0-100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void directLevelGroup(int group, int level, int fadeTime) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message = '>V:1,C:13,G:$group,L:$level,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Set a direct level to a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [level] - The level percentage (0-100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void directLevelDevice(int cluster, int router, int subnet, int device,
      int level, int fadeTime) {
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
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message =
        '>V:1,C:14,@$cluster.$router.$subnet.$device,L:$level,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Send a direct proportion message to a group
  ///
  /// [group] - The group number (1-16383)
  /// [proportion] - The proportion percentage (-100 to 100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void directProportionGroup(int group, int proportion, int fadeTime) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (proportion < -100 || proportion > 100) {
      throw ArgumentError('Proportion must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message = '>V:1,C:15,G:$group,P:$proportion,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Send a direct proportion message to a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [proportion] - The proportion percentage (-100 to 100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void directProportionDevice(int cluster, int router, int subnet, int device,
      int proportion, int fadeTime) {
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
    if (proportion < -100 || proportion > 100) {
      throw ArgumentError('Proportion must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message =
        '>V:1,C:16,@$cluster.$router.$subnet.$device,P:$proportion,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Modify the proportion level of a group
  ///
  /// [group] - The group number (1-16383)
  /// [proportionChange] - The proportion change (-100 to 100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void modifyProportionGroup(int group, int proportionChange, int fadeTime) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (proportionChange < -100 || proportionChange > 100) {
      throw ArgumentError('Proportion change must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message = '>V:1,C:17,G:$group,P:$proportionChange,F:$fadeTime#';
    _protocol.sendMessage(message);
  }

  /// Modify the proportion level of a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  /// [proportionChange] - The proportion change (-100 to 100)
  /// [fadeTime] - The fade time in tenths of a second (0-65535, max ~109 minutes)
  void modifyProportionDevice(int cluster, int router, int subnet, int device,
      int proportionChange, int fadeTime) {
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
    if (proportionChange < -100 || proportionChange > 100) {
      throw ArgumentError('Proportion change must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final message =
        '>V:1,C:18,@$cluster.$router.$subnet.$device,P:$proportionChange,F:$fadeTime#';
    _protocol.sendMessage(message);
  }
}
