import 'protocol_constants.dart';

class ProtocolUtils {
  static bool isErrorResponse(String response) {
    return response.startsWith(MessageType.error);
  }

  static int? getErrorCode(String errorResponse) {
    if (!isErrorResponse(errorResponse)) {
      return null;
    }

    final parts = errorResponse.split(MessageType.answer);
    if (parts.length != 2) {
      return null;
    }

    var errorCodeStr = parts[1];
    if (errorCodeStr.endsWith(MessageType.terminator)) {
      errorCodeStr = errorCodeStr.substring(0, errorCodeStr.length - 1);
    }

    return int.tryParse(errorCodeStr);
  }

  static String formatDeviceAddress(
      int cluster, int router, int subnet, int device) {
    return '$cluster${MessageType.addressDelimiter}$router${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device';
  }
}
