import '../models/helvar_models/helvar_device.dart';

extension HelvarDeviceAddressParsing on HelvarDevice {
  List<int> get parsedAddress {
    final parts = address.split('.');
    if (parts.length != 4) {
      throw FormatException('Invalid Helvar device address: $address');
    }
    return parts.map(int.parse).toList();
  }

  int get cluster => parsedAddress[0];
  int get router => parsedAddress[1];
  int get subnet => parsedAddress[2];
  int get device => parsedAddress[3];

  String get routerAddress => '@$cluster.$router';
}
