import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/button_point_status_service.dart';
import 'router_connection_provider.dart';

final buttonPointStatusServiceProvider =
    Provider<ButtonPointStatusService>((ref) {
  final commandService = ref.watch(routerCommandServiceProvider);
  return ButtonPointStatusService(commandService);
});

final buttonPointStatusStreamProvider =
    StreamProvider<ButtonPointStatus>((ref) {
  final service = ref.watch(buttonPointStatusServiceProvider);
  return service.statusStream;
});

final buttonPointStatusProvider =
    Provider.family<ButtonPointStatus?, String>((ref, key) {
  // Key format: "deviceAddress_buttonId"
  final parts = key.split('_');
  if (parts.length != 2) return null;

  final deviceAddress = parts[0];
  final buttonId = int.tryParse(parts[1]);
  if (buttonId == null) return null;

  final service = ref.watch(buttonPointStatusServiceProvider);
  return service.getButtonPointStatus(deviceAddress, buttonId);
});

class ButtonPointMonitoringNotifier extends StateNotifier<Map<String, bool>> {
  final ButtonPointStatusService _statusService;

  ButtonPointMonitoringNotifier(this._statusService) : super({});

  Future<void> startMonitoring(
      String deviceAddress, String routerIpAddress, dynamic device) async {
    final key = '$deviceAddress@$routerIpAddress';
    if (!state[key]! == true) {
      await _statusService.startMonitoring(device, routerIpAddress);
      state = {...state, key: true};
    }
  }

  void stopMonitoring(String deviceAddress, String routerIpAddress) {
    final key = '$deviceAddress@$routerIpAddress';
    if (state[key] == true) {
      _statusService.stopMonitoring(deviceAddress, routerIpAddress);
      state = {...state, key: false};
    }
  }

  @override
  void dispose() {
    _statusService.dispose();
    super.dispose();
  }
}

final buttonPointMonitoringProvider =
    StateNotifierProvider<ButtonPointMonitoringNotifier, Map<String, bool>>(
        (ref) {
  final statusService = ref.watch(buttonPointStatusServiceProvider);
  return ButtonPointMonitoringNotifier(statusService);
});
