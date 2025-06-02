import 'package:flutter/material.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';

class NetworkInterfaceDialog extends StatefulWidget {
  const NetworkInterfaceDialog({super.key, required this.interfaces});

  final List<NetworkInterfaceDetails> interfaces;

  @override
  NetworkInterfaceDialogState createState() => NetworkInterfaceDialogState();
}

class NetworkInterfaceDialogState extends State<NetworkInterfaceDialog> {
  NetworkInterfaceDetails? selectedInterface;

  @override
  void initState() {
    super.initState();
    if (widget.interfaces.isNotEmpty) {
      selectedInterface = widget.interfaces.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Interface / Address'),
      content: DropdownButton<NetworkInterfaceDetails>(
        isExpanded: true,
        value: selectedInterface,
        onChanged: (NetworkInterfaceDetails? newValue) {
          if (newValue != null) {
            setState(() {
              selectedInterface = newValue;
            });
          }
        },
        items: widget.interfaces.map<DropdownMenuItem<NetworkInterfaceDetails>>(
          (NetworkInterfaceDetails interface) {
            return DropdownMenuItem<NetworkInterfaceDetails>(
              value: interface,
              child: Text('${interface.name} - ${interface.ipv4 ?? "No IP"}'),
            );
          },
        ).toList(),
      ),
      actions: <Widget>[
        cancelAction(context),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(selectedInterface);
          },
        ),
      ],
    );
  }
}

class NetworkInterfaceDetails {
  final String name;
  String? ipv4;
  String? subnetMask;
  String? gateway;

  NetworkInterfaceDetails({required this.name});

  @override
  String toString() {
    return '''
Interface: $name
  IPv4: ${ipv4 ?? 'N/A'} Subnet Mask: ${subnetMask ?? 'N/A'}
''';
  }
}
