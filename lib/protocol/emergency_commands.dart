// protocol/emergency_commands.dart
//
// A collection of emergency test commands for the Helvar protocol
// These commands manage emergency lighting tests and status queries

import 'dart:async';
import 'helvar_protocol.dart';

/// EmergencyCommands provides a high-level interface for all emergency lighting operations
/// available in the Helvar protocol.
class EmergencyCommands {
  final HelvarProtocol _protocol;

  EmergencyCommands(this._protocol);

  /// Request an Emergency Function Test across a group
  ///
  /// [group] - The group number (1-16383)
  void emergencyFunctionTestGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    final message = '>V:1,C:19,G:$group#';
    _protocol.sendMessage(message);
  }

  /// Request an Emergency Function Test for a specific device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  void emergencyFunctionTestDevice(
      int cluster, int router, int subnet, int device) {
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

    final message = '>V:1,C:20,@$cluster.$router.$subnet.$device#';
    _protocol.sendMessage(message);
  }

  /// Request an Emergency Duration Test across a group
  ///
  /// [group] - The group number (1-16383)
  void emergencyDurationTestGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    final message = '>V:1,C:21,G:$group#';
    _protocol.sendMessage(message);
  }

  /// Request an Emergency Duration Test for a specific device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  void emergencyDurationTestDevice(
      int cluster, int router, int subnet, int device) {
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

    final message = '>V:1,C:22,@$cluster.$router.$subnet.$device#';
    _protocol.sendMessage(message);
  }

  /// Stop all Emergency Tests across a group
  ///
  /// [group] - The group number (1-16383)
  void stopEmergencyTestsGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    final message = '>V:1,C:23,G:$group#';
    _protocol.sendMessage(message);
  }

  /// Stop any Emergency Test running in a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  void stopEmergencyTestsDevice(
      int cluster, int router, int subnet, int device) {
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

    final message = '>V:1,C:24,@$cluster.$router.$subnet.$device#';
    _protocol.sendMessage(message);
  }

  /// Query the time of the last Emergency Function Test
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<DateTime?> queryEmergencyFunctionTestTime(
      int cluster, int router, int subnet, int device) async {
    Completer<DateTime?> completer = Completer<DateTime?>();

    _protocol.addResponseHandler('170', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final timeString = parts[1].replaceAll('#', '');

        try {
          // Parse the date-time string in the format: "hh:mm:ss dd-MMM-yyyy"
          final dateTime = _parseEmergencyDateTime(timeString);
          completer.complete(dateTime);
        } catch (e) {
          completer.complete(null);
        }
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:170,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the state of the Emergency Function Test
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<int> queryEmergencyFunctionTestState(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('171', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final state = int.tryParse(parts[1].replaceAll('#', ''));
        if (state != null) {
          completer.complete(state);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:171,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the time of the last Emergency Duration Test
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<DateTime?> queryEmergencyDurationTestTime(
      int cluster, int router, int subnet, int device) async {
    Completer<DateTime?> completer = Completer<DateTime?>();

    _protocol.addResponseHandler('172', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final timeString = parts[1].replaceAll('#', '');

        try {
          // Parse the date-time string in the format: "hh:mm:ss dd-MMM-yyyy"
          final dateTime = _parseEmergencyDateTime(timeString);
          completer.complete(dateTime);
        } catch (e) {
          completer.complete(null);
        }
        return true;
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:172,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the state of the Emergency Duration Test
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<int> queryEmergencyDurationTestState(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('173', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final state = int.tryParse(parts[1].replaceAll('#', ''));
        if (state != null) {
          completer.complete(state);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:173,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the remaining charge of the emergency battery
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<int> queryEmergencyBatteryCharge(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('174', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final charge = int.tryParse(parts[1].replaceAll('#', ''));
        if (charge != null) {
          completer.complete(charge);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:174,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the total running time of the emergency battery
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<int> queryEmergencyBatteryTime(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('175', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final time = int.tryParse(parts[1].replaceAll('#', ''));
        if (time != null) {
          completer.complete(time);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:175,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Query the total lamp running time from any power source
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  Future<int> queryEmergencyTotalLampTime(
      int cluster, int router, int subnet, int device) async {
    Completer<int> completer = Completer<int>();

    _protocol.addResponseHandler('176', (String response) {
      final parts = response.split('=');
      if (parts.length > 1) {
        final time = int.tryParse(parts[1].replaceAll('#', ''));
        if (time != null) {
          completer.complete(time);
          return true;
        }
      }
      return false;
    });

    _protocol.sendMessage('>V:1,C:176,@$cluster.$router.$subnet.$device#');

    return completer.future;
  }

  /// Reset the Emergency Battery and Total Lamp Time for a group
  ///
  /// [group] - The group number (1-16383)
  void resetEmergencyBatteryGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    final message = '>V:1,C:205,G:$group#';
    _protocol.sendMessage(message);
  }

  /// Reset the Emergency Battery and Total Lamp Time for a device
  ///
  /// [cluster] - The cluster number (1-253)
  /// [router] - The router number (1-254)
  /// [subnet] - The subnet number (1-4)
  /// [device] - The device number (1-255)
  void resetEmergencyBatteryDevice(
      int cluster, int router, int subnet, int device) {
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

    final message = '>V:1,C:206,@$cluster.$router.$subnet.$device#';
    _protocol.sendMessage(message);
  }

  // Helper method to parse emergency date-time strings
  DateTime? _parseEmergencyDateTime(String timeString) {
    // Format: "hh:mm:ss dd-MMM-yyyy"
    final parts = timeString.split(' ');
    if (parts.length != 2) return null;

    final timeParts = parts[0].split(':');
    final dateParts = parts[1].split('-');

    if (timeParts.length != 3 || dateParts.length != 3) return null;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    final second = int.tryParse(timeParts[2]);

    final day = int.tryParse(dateParts[0]);

    // Convert month name to number
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = monthNames.indexOf(dateParts[1]) + 1;

    final year = int.tryParse(dateParts[2]);

    if (hour == null ||
        minute == null ||
        second == null ||
        day == null ||
        month <= 0 ||
        year == null) {
      return null;
    }

    return DateTime(year, month, day, hour, minute, second);
  }
}
