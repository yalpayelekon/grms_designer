import 'package:flutter/material.dart';
import 'dart:io';

class NetworkInterfaceDialog extends StatefulWidget {
  const NetworkInterfaceDialog({Key? key, required this.interfaces})
      : super(key: key);

  final List<NetworkInterface> interfaces;

  @override
  _NetworkInterfaceDialogState createState() => _NetworkInterfaceDialogState();
}

class _NetworkInterfaceDialogState extends State<NetworkInterfaceDialog> {
  NetworkInterface? selectedInterface;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.interfaces.isNotEmpty) {
      selectedInterface = widget.interfaces.first;
      if (selectedInterface!.addresses.isNotEmpty) {
        selectedAddress = selectedInterface!.addresses.first.address;
      }
    }
  }

  String getDisplayName(NetworkInterface interface) {
    if (interface.addresses.isEmpty) {
      return '${interface.name} (No address)';
    }
    return '${interface.name} - ${interface.addresses.first.address}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Interface / Address'),
      content: DropdownButton<NetworkInterface>(
        isExpanded: true,
        value: selectedInterface,
        onChanged: (NetworkInterface? newValue) {
          if (newValue != null) {
            setState(() {
              selectedInterface = newValue;
              if (selectedInterface!.addresses.isNotEmpty) {
                selectedAddress = selectedInterface!.addresses.first.address;
              } else {
                selectedAddress = null;
              }
            });
          }
        },
        items: widget.interfaces.map<DropdownMenuItem<NetworkInterface>>(
            (NetworkInterface interface) {
          return DropdownMenuItem<NetworkInterface>(
            value: interface,
            child: Text(getDisplayName(interface)),
          );
        }).toList(),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop({
              'interface': selectedInterface,
              'address': selectedAddress,
            });
          },
        ),
      ],
    );
  }
}
