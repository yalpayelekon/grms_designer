import 'package:grms_designer/utils/core/logger.dart';

import '../../comm/router_command_service.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/output_device.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import 'polling_task.dart';

class DeviceStatusPollingTask extends PollingTask {
  final RouterCommandService commandService;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(HelvarDevice updatedDevice)? onDeviceUpdated;

  DeviceStatusPollingTask({
    required this.commandService,
    required this.router,
    required this.device,
    this.onDeviceUpdated,
    super.interval = const Duration(minutes: 5),
  }) : super(
         id: 'device_status_${router.address}_${device.address}',
         name: 'Device ${device.address} Status',
         parameters: {
           'routerAddress': router.address,
           'deviceAddress': device.address,
           'deviceType': device.helvarType,
         },
       );

  @override
  Future<PollingResult> execute() async {
    try {
      logDebug('Polling status for device ${device.address}');

      final results = <String, dynamic>{};

      final stateCommand = HelvarNetCommands.queryDeviceState(device.address);
      final stateResult = await commandService.sendCommand(
        router.ipAddress,
        stateCommand,
      );

      if (stateResult.success && stateResult.response != null) {
        final stateValue = ProtocolParser.extractResponseValue(
          stateResult.response!,
        );
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue) ?? 0;
          results['deviceStateCode'] = stateCode;
          results['deviceState'] = _getStateFlagsDescription(stateCode);
        }
      }

      if (device is HelvarDriverOutputDevice) {
        final levelCommand = HelvarNetCommands.queryLoadLevel(device.address);
        final levelResult = await commandService.sendCommand(
          router.ipAddress,
          levelCommand,
        );

        if (levelResult.success && levelResult.response != null) {
          final levelValue = ProtocolParser.extractResponseValue(
            levelResult.response!,
          );
          if (levelValue != null) {
            final level = double.tryParse(levelValue) ?? 0.0;
            results['outputLevel'] = level;
          }
        }
      }

      if (results.containsKey('deviceStateCode')) {
        device.deviceStateCode = results['deviceStateCode'];
      }
      if (results.containsKey('deviceState')) {
        device.state = results['deviceState'];
      }
      if (device is HelvarDriverOutputDevice &&
          results.containsKey('outputLevel')) {
        (device as HelvarDriverOutputDevice).level =
            (results['outputLevel'] as double).round();
      }

      onDeviceUpdated?.call(device);

      return PollingResult.success(results);
    } catch (e) {
      return PollingResult.failure('Error polling device status: $e');
    }
  }

  String _getStateFlagsDescription(int flags) {
    final descriptions = <String>[];

    if (flags == 0) return 'Normal';

    if ((flags & 0x00000001) != 0) descriptions.add('Disabled');
    if ((flags & 0x00000002) != 0) descriptions.add('Lamp Failure');
    if ((flags & 0x00000004) != 0) descriptions.add('Missing');
    if ((flags & 0x00000008) != 0) descriptions.add('Faulty');

    return descriptions.join(', ');
  }

  @override
  void onStart() {
    logInfo('Started status polling for device ${device.address}');
  }

  @override
  void onStop() {
    logInfo('Stopped status polling for device ${device.address}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    logError(
      'Device status polling error for ${device.address}: $error',
      stackTrace: stackTrace,
    );
  }
}
