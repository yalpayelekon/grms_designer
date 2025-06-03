import 'package:grms_designer/utils/core/logger.dart';

import '../../comm/router_command_service.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/output_device.dart';
import '../../models/helvar_models/output_point.dart';
import '../../services/device_query_service.dart';
import 'polling_task.dart';

class OutputPointPollingTask extends PollingTask {
  final RouterCommandService commandService;
  final HelvarRouter router;
  final HelvarDriverOutputDevice device;
  final List<int> pointIds; // Which points to poll
  final Function(
    HelvarDriverOutputDevice device,
    List<OutputPoint> updatedPoints,
  )?
  onPointsUpdated;

  OutputPointPollingTask({
    required this.commandService,
    required this.router,
    required this.device,
    required this.pointIds,
    this.onPointsUpdated,
    Duration interval = const Duration(seconds: 30),
  }) : super(
         id: 'output_points_${router.address}_${device.address}_${pointIds.join('_')}',
         name: 'Output Points ${device.address}',
         interval: interval,
         parameters: {
           'routerAddress': router.address,
           'deviceAddress': device.address,
           'pointIds': pointIds,
         },
       );

  @override
  Future<PollingResult> execute() async {
    try {
      final deviceQueryService = DeviceQueryService(commandService);
      final updatedPoints = <OutputPoint>[];
      final results = <String, dynamic>{};

      for (final pointId in pointIds) {
        try {
          final success = await deviceQueryService.queryOutputDevicePoint(
            router.ipAddress,
            device,
            pointId,
          );

          if (success) {
            final point = device.getPointById(pointId);
            if (point != null) {
              updatedPoints.add(point);
              results['point_$pointId'] = point.value;
            }
          }
        } catch (e) {
          logWarning(
            'Error polling point $pointId for device ${device.address}: $e',
          );
        }
      }

      // Notify callback if any points were updated
      if (updatedPoints.isNotEmpty) {
        onPointsUpdated?.call(device, updatedPoints);
      }

      return PollingResult.success(results);
    } catch (e) {
      return PollingResult.failure('Error polling output points: $e');
    }
  }

  @override
  void onStart() {
    logInfo(
      'Started output point polling for device ${device.address}, points: $pointIds',
    );
  }

  @override
  void onStop() {
    logInfo('Stopped output point polling for device ${device.address}');
  }
}
