import '../utils/core/logger.dart';

class ProtocolParser {
  static String? extractResponseValue(String response) {
    if ((response.startsWith('?') || response.startsWith('!')) &&
        response.contains('=')) {
      final parts = response.split('=');
      if (parts.length > 1) {
        return parts[1].replaceAll('#', '');
      }
    }
    return null;
  }

  static Map<int, int> parseDeviceAddressesAndTypes(String response) {
    final deviceMap = <int, int>{};
    final pairs = response.split(',');

    for (final pair in pairs) {
      if (pair.contains('@')) {
        final parts = pair.split('@');
        if (parts.length == 2) {
          try {
            final deviceType = int.parse(parts[0]);
            final deviceId = int.parse(parts[1]);
            deviceMap[deviceId] = deviceType;
          } catch (e) {
            logError('Error parsing device pair: $pair - $e');
          }
        }
      }
    }

    return deviceMap;
  }

  static bool isSuccessResponse(String response) {
    return response.startsWith('?');
  }

  static bool isErrorResponse(String response) {
    return response.startsWith('!');
  }

  static int? getCommandCode(String response) {
    if (!response.startsWith('?') && !response.startsWith('!')) {
      return null;
    }

    final commandMatch = RegExp(r'C:(\d+)').firstMatch(response);
    if (commandMatch != null) {
      return int.tryParse(commandMatch.group(1)!);
    }
    return null;
  }

  static int? getVersion(String response) {
    if (!response.startsWith('?') && !response.startsWith('!')) {
      return null;
    }

    final versionMatch = RegExp(r'V:(\d+)').firstMatch(response);
    if (versionMatch != null) {
      return int.tryParse(versionMatch.group(1)!);
    }
    return null;
  }

  static String? getDeviceAddress(String response) {
    if (!response.startsWith('?') && !response.startsWith('!')) {
      return null;
    }

    final addressMatch = RegExp(r'@([\d.]+)').firstMatch(response);
    if (addressMatch != null) {
      return addressMatch.group(1);
    }
    return null;
  }

  static Map<String, dynamic> parseFullResponse(String response) {
    return {
      'isSuccess': isSuccessResponse(response),
      'isError': isErrorResponse(response),
      'version': getVersion(response),
      'commandCode': getCommandCode(response),
      'deviceAddress': getDeviceAddress(response),
      'value': extractResponseValue(response),
      'rawResponse': response,
    };
  }
}
