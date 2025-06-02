import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grms_designer/utils/ui_helpers.dart';

import '../screens/dialogs/network_interface_dialog.dart';
import 'logger.dart';

Future<List<NetworkInterfaceDetails>> getNetworkInterfaces() async {
  final result = await Process.run('ipconfig', ['/all']);
  final output = result.stdout.toString();
  final interfaces = parseIpConfig(output);
  final filteredInterfaces = interfaces.where((interface) {
    return interface.ipv4 != null && interface.subnetMask != null;
  }).toList();
  if (filteredInterfaces.isEmpty) {
    logWarning('No valid interfaces found.');
    logVerbose('Raw ipconfig output:\n$output');
    return [];
  }
  return filteredInterfaces;
}

Future<NetworkInterfaceDetails?> selectNetworkInterface(
  BuildContext context,
) async {
  try {
    List<NetworkInterfaceDetails> interfaces = await getNetworkInterfaces();

    if (interfaces.isEmpty) {
      showSnackBarMsg(context, 'No network interfaces found');
      return null;
    }

    final result = await showDialog<NetworkInterfaceDetails>(
      context: context,
      builder: (BuildContext context) {
        return NetworkInterfaceDialog(interfaces: interfaces);
      },
    );

    return result;
  } catch (e) {
    logError('Error selecting network interface: $e');
    showSnackBarMsg(context, 'Error selecting network interface.');
    return null;
  }
}

List<NetworkInterfaceDetails> parseIpConfig(String output) {
  final interfaces = <NetworkInterfaceDetails>[];
  final lines = output.split('\n');
  NetworkInterfaceDetails? currentInterface;
  for (final line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.contains('adapter') && trimmedLine.endsWith(':')) {
      if (currentInterface != null &&
          (currentInterface.ipv4 != null ||
              currentInterface.subnetMask != null)) {
        interfaces.add(currentInterface);
      }
      final name = trimmedLine
          .replaceAll('adapter', '')
          .replaceAll(':', '')
          .trim();
      currentInterface = NetworkInterfaceDetails(name: name);
    } else if (currentInterface != null) {
      if (trimmedLine.startsWith('IPv4 Address') ||
          trimmedLine.startsWith('IPv4-adres')) {
        currentInterface.ipv4 = _cleanValue(_extractAfterColon(trimmedLine));
      } else if (trimmedLine.startsWith('Subnet Mask') ||
          trimmedLine.startsWith('Subnetmasker')) {
        currentInterface.subnetMask = _cleanValue(
          _extractAfterColon(trimmedLine),
        );
      } else if (trimmedLine.startsWith('Default Gateway') ||
          trimmedLine.startsWith('Standaardgateway')) {
        currentInterface.gateway = _cleanValue(_extractAfterColon(trimmedLine));
      }
    }
  }
  if (currentInterface != null &&
      (currentInterface.ipv4 != null || currentInterface.subnetMask != null)) {
    interfaces.add(currentInterface);
  }
  return interfaces;
}

String calculateBroadcastAddress(String ipAddress, String subnetMask) {
  List<String> ipParts = ipAddress.split('.');
  List<String> maskParts = subnetMask.split('.');
  List<String> broadcastParts = [];
  for (int i = 0; i < 4; i++) {
    int ip = int.parse(ipParts[i]);
    int mask = int.parse(maskParts[i]);
    int broadcast = ip | (~mask & 0xFF);
    broadcastParts.add(broadcast.toString());
  }
  return broadcastParts.join('.');
}

String _extractAfterColon(String line) {
  final parts = line.split(':');
  if (parts.length < 2) return '';
  return parts.sublist(1).join(':').trim();
}

String _cleanValue(String value) {
  return value.replaceAll(RegExp(r'\(.*\)'), '').trim();
}
