import 'package:flutter/material.dart';
import '../../models/helvar_models/helvar_device.dart';

String getDeviceIconAsset(HelvarDevice? device) {
  if (device == null) return 'assets/icons/device.png';

  String hexId = device.hexId.startsWith('0x')
      ? device.hexId.substring(2)
      : device.hexId;

  hexId = hexId.toLowerCase();

  if (device.isMultisensor ||
      device.helvarType == 'input' &&
          device.props.toLowerCase().contains('sensor')) {
    if (hexId == '312502') return 'assets/icons/312.png';
    if (hexId == '315602') return 'assets/icons/315.png';
    if (hexId == '5749701') return 'assets/icons/IR-Quattro-HD.png';
    if (hexId == '5748001') return 'assets/icons/HF-360.png';
    if (hexId == '5745901') return 'assets/icons/Dual-HF.png';
    if (hexId == '6624601' || hexId == '6626001') {
      return 'assets/icons/IS-3360-MX.png';
    }

    return 'assets/icons/sensor.png';
  }

  if (device.isButtonDevice || device.helvarType == 'input') {
    if (hexId == '100802') return 'assets/icons/100.png';
    if (hexId == '110702') return 'assets/icons/110.png';
    if (hexId == '111402') return 'assets/icons/111.png';
    if (hexId == '121302') return 'assets/icons/121.png';
    if (hexId == '122002') return 'assets/icons/122.png';
    if (hexId == '124402') return 'assets/icons/124.png';
    if (hexId == '125102') return 'assets/icons/125.png';
    if (hexId == '126802') return 'assets/icons/126.png';
    if (hexId == '131202' || hexId.contains('131')) {
      return 'assets/icons/131.png';
    }
    if (hexId == '134302' || hexId.contains('134')) {
      return 'assets/icons/134.png';
    }
    if (hexId == '135002' || hexId.contains('135')) {
      return 'assets/icons/135.png';
    }
    if (hexId == '136702' || hexId.contains('136')) {
      return 'assets/icons/136.png';
    }
    if (hexId == '137402' || hexId.contains('137')) {
      return 'assets/icons/137.png';
    }
    if (hexId == '170102') return 'assets/icons/170.png';
    if (hexId.contains('142')) return 'assets/icons/142WD2.png';
    if (hexId.contains('144')) return 'assets/icons/144WD2.png';
    if (hexId.contains('146')) return 'assets/icons/146WD2.png';
    if (hexId.contains('148')) return 'assets/icons/148WD2.png';
    if (hexId.contains('160')) return 'assets/icons/160.PNG';
    if (hexId.contains('935')) return 'assets/icons/935.png';
    if (hexId.contains('939')) return 'assets/icons/939.png';
    if (hexId.contains('434')) return 'assets/icons/EnOcean.png';

    return 'assets/icons/device.png';
  }

  if (device.helvarType == 'output') {
    if (hexId.contains('55') || hexId == '601' || hexId == '801') {
      return 'assets/icons/LEDunit.png';
    }

    if (hexId.contains('492') ||
        hexId.contains('493') ||
        hexId.contains('42') ||
        hexId.contains('43') ||
        hexId == '1') {
      return 'assets/icons/ballast.png';
    }

    if (hexId.contains('416') ||
        hexId.contains('425') ||
        hexId.contains('452') ||
        hexId.contains('454') ||
        hexId.contains('455') ||
        hexId.contains('458') ||
        hexId.contains('804') ||
        hexId == '401') {
      return 'assets/icons/dimmer.png';
    }

    if (hexId.contains('490')) return 'assets/icons/490.png';
    if (hexId.contains('491') ||
        hexId.contains('492') ||
        hexId.contains('493') ||
        hexId.contains('494') ||
        hexId.contains('498') ||
        hexId.contains('499') ||
        hexId == '701' ||
        hexId == '1793') {
      return 'assets/icons/491.png';
    }

    if (hexId.contains('472') ||
        hexId.contains('474') ||
        hexId.contains('478') ||
        hexId == '501') {
      return 'assets/icons/472.png';
    }

    if (hexId.contains('208') || hexId.contains('108')) {
      return 'assets/icons/dmx.png';
    }
  }

  if (device.helvarType == 'emergency' || device.emergency) {
    return 'assets/icons/outputemergency.png';
  }

  if (hexId.contains('444') || hexId.contains('445') || hexId.contains('441')) {
    return 'assets/icons/444.png';
  }

  if (hexId.contains('942')) {
    return 'assets/icons/942.png';
  }

  return 'assets/icons/device.png';
}

Widget getDeviceIconWidget(
  HelvarDevice? device, {
  IconData? iconData,
  double size = 24.0,
}) {
  if (iconData != null) {
    return Icon(iconData, size: size);
  }

  return Image.asset(getDeviceIconAsset(device), width: size, height: size);
}
