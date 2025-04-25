// protocol/query_commands.dart
//
// A collection of query commands for the Helvar protocol
// These commands retrieve information from devices, routers, and the system

import 'dart:async';
import 'helvar_protocol.dart';

/// QueryCommands provides a high-level interface for all query operations
/// available in the Helvar protocol.
class QueryCommands {
  final HelvarProtocol _protocol;

  QueryCommands(this._protocol);

  /// Query the device state
  ///
  /// Returns a bitmask containing state information about the device
  Future<int> queryDeviceState(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    // Register a one-time response handler for this specific query
    _protocol.addResponseHandler('110', (String response) {
      // Parse the response to extract the state value
      final parts = response.split('=');
      if (parts.length > 1) {
        final state = int.tryParse(parts[1].replaceAll('#', ''));
        if (state != null) {
          completer.complete(state);
          return true; // Remove this handler after processing
        }
      }
      return false; // Keep handler active if parsing failed
    });

    // Send the query
    _protocol.sendMessage('>V:1,C:110,@$cluster.$router.$subnet.$device#');

    // Return the future that will complete when a response is received
    return completer.future;
  }

  /// Query whether the device is disabled
  Future<bool> queryDeviceIsDisabled(
      int cluster, int router, int subnet, int device) async {
    Completer<bool> completer = Completer<bool>();

    _protocol.addResponseHandler('111', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final disabled = int.tryParse(parts[1].replaceAll('#', ''));
        if (disabled != null) {
          completer.complete(disabled == 1);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:111,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query whether the lamp has failed
  Future<bool> queryLampFailure(
      int cluster, int router, int subnet, int device) async {
    Completer<bool> completer = Completer<bool>();

    _protocol.addResponseHandler('112', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final failed = int.tryParse(parts[1].replaceAll('#', ''));
        if (failed != null) {
          completer.complete(failed == 1);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:112,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query whether the device is missing
  Future<bool> queryDeviceIsMissing(
      int cluster, int router, int subnet, int device) async {
    Completer<bool> completer = Completer<bool>();

    _protocol.addResponseHandler('113', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final missing = int.tryParse(parts[1].replaceAll('#', ''));
        if (missing != null) {
          completer.complete(missing == 1);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:113,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query whether the device is faulty
  Future<bool> queryDeviceIsFaulty(
      int cluster, int router, int subnet, int device) async {
    Completer<bool> completer = Completer<bool>();

    _protocol.addResponseHandler('114', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final faulty = int.tryParse(parts[1].replaceAll('#', ''));
        if (faulty != null) {
          completer.complete(faulty == 1);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:114,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the load level of a device (0-100%)
  Future<int> queryLoadLevel(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('152', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final level = int.tryParse(parts[1].replaceAll('#', ''));
        if (level != null) {
          // Check if this is a special "off but with level" response
          if (level > 2147483600) {
            // Device is off but has a stored level
            completer.complete(0);
          } else {
            completer.complete(level);
          }
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:152,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the power consumption of a device in watts
  Future<int> queryPowerConsumption(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('160', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final power = int.tryParse(parts[1].replaceAll('#', ''));
        if (power != null) {
          completer.complete(power);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:160,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the total power consumption of a group in watts
  Future<int> queryGroupPowerConsumption(int group) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('161', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final power = int.tryParse(parts[1].replaceAll('#', ''));
        if (power != null) {
          completer.complete(power);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:161,G:$group#');

    return completer.future;
  }

  /// Query the type of device
  Future<String> queryDeviceType(
      int cluster, int router, int subnet, int device) async {
    Completer<String> completer = Completer<String>();

    _protocol.addResponseHandler('104', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final deviceType = parts[1].replaceAll('#', '');
        completer.complete(deviceType);
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:104,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query description of a device
  Future<String> queryDeviceDescription(
      int cluster, int router, int subnet, int device) async {
    Completer<String> completer = Completer<String>();

    _protocol.addResponseHandler('106', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final description = parts[1].replaceAll('#', '');
        completer.complete(description);
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:106,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query all available clusters in the system
  Future<List<int>> queryClusters() async {
    Completer<List<int>> completer = Completer<List<int>>();

    _protocol.addResponseHandler('101', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final clustersPart = parts[1].replaceAll('#', '');
        final clusters = clustersPart
            .split(',')
            .map((e) => int.tryParse(e))
            .where((e) => e != null)
            .map((e) => e!)
            .toList();

        completer.complete(clusters);
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:101#');

    return completer.future;
  }

  /// Query all routers in a specific cluster
  Future<List<int>> queryRouters(int cluster) async {
    Completer<List<int>> completer = Completer<List<int>>();

    _protocol.addResponseHandler('102', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final routersPart = parts[1].replaceAll('#', '');
        final routers = routersPart
            .split(',')
            .map((e) => int.tryParse(e))
            .where((e) => e != null)
            .map((e) => e!)
            .toList();

        completer.complete(routers);
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:102,@$cluster#');

    return completer.future;
  }

  /// Query the last scene recalled in a block for a group
  Future<int> queryLastSceneInBlock(int group, int block) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('103', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final scene = int.tryParse(parts[1].replaceAll('#', ''));
        if (scene != null) {
          // Special cases for the scene value:
          if (scene == 128) {
            // Off
            completer.complete(0);
          } else if (scene == 129) {
            // Min level
            completer.complete(-1);
          } else if (scene == 130) {
            // Max level
            completer.complete(-2);
          } else if (scene >= 137 && scene <= 237) {
            // Last Scene Percentage (137=0%, 237=100%)
            completer.complete(-3); // Special indicator for percentage mode
          } else {
            // Regular scene number
            completer.complete(scene);
          }
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:103,G:$group,B:$block#');

    return completer.future;
  }

  /// Query the current system time from the router
  Future<DateTime> queryTime() async {
    Completer<DateTime> completer = Completer<DateTime>();

    _protocol.addResponseHandler('185', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final timestamp = int.tryParse(parts[1].replaceAll('#', ''));
        if (timestamp != null) {
          final dateTime =
              DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          completer.complete(dateTime);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:185#');

    return completer.future;
  }

  /// Query software version of the router
  Future<String> querySoftwareVersion() async {
    Completer<String> completer = Completer<String>();

    _protocol.addResponseHandler('190', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final version = parts[1].replaceAll('#', '');
        completer.complete(version);
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:190#');

    return completer.future;
  }
}
