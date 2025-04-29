// Create a new file: lib/screens/add_device_dialog.dart
import 'package:flutter/material.dart';
import '../models/emergency_device.dart';
import '../models/helvar_device.dart';
import '../models/input_device.dart';
import '../models/output_device.dart';

enum DeviceType { output, input, emergency }

class AddDeviceDialog extends StatefulWidget {
  final int nextDeviceId;

  const AddDeviceDialog({
    Key? key,
    required this.nextDeviceId,
  }) : super(key: key);

  @override
  AddDeviceDialogState createState() => AddDeviceDialogState();
}

class AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  DeviceType _deviceType = DeviceType.output;
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Device'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DeviceType>(
                decoration: const InputDecoration(
                  labelText: 'Device Type',
                  border: OutlineInputBorder(),
                ),
                value: _deviceType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _deviceType = value;
                    });
                  }
                },
                items: DeviceType.values.map((type) {
                  return DropdownMenuItem<DeviceType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Device Address (e.g., 1.1.1.1)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device address';
                  }
                  if (!RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(value)) {
                    return 'Please enter a valid address (e.g., 1.1.1.1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final HelvarDevice device;

              switch (_deviceType) {
                case DeviceType.input:
                  device = HelvarDriverInputDevice(
                    deviceId: widget.nextDeviceId,
                    address: _addressController.text,
                    description: _descriptionController.text,
                    props: '',
                  );
                  break;
                case DeviceType.emergency:
                  device = HelvarDriverEmergencyDevice(
                    deviceId: widget.nextDeviceId,
                    address: _addressController.text,
                    description: _descriptionController.text,
                    emergency: true,
                  );
                  break;
                case DeviceType.output:
                default:
                  device = HelvarDriverOutputDevice(
                    deviceId: widget.nextDeviceId,
                    address: _addressController.text,
                    description: _descriptionController.text,
                  );
                  break;
              }

              Navigator.of(context).pop(device);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
