import 'package:flutter/material.dart';
import '../../models/helvar_models/emergency_device.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';

enum DeviceType { output, input, emergency }

class AddDeviceDialog extends StatefulWidget {
  final int nextDeviceId;
  final List<String> existingSubnets;

  const AddDeviceDialog({
    super.key,
    required this.nextDeviceId,
    required this.existingSubnets,
  });

  @override
  AddDeviceDialogState createState() => AddDeviceDialogState();
}

class AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  DeviceType _deviceType = DeviceType.output;
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubnet;
  final _deviceIndexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingSubnets.isNotEmpty) {
      _selectedSubnet = widget.existingSubnets.first;
    }
  }

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
              if (widget.existingSubnets.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subnet',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubnet,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSubnet = value;
                      });
                    }
                  },
                  items: [
                    ...widget.existingSubnets.map((subnet) {
                      return DropdownMenuItem<String>(
                        value: subnet,
                        child: Text('Subnet $subnet'),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: 'custom',
                      child: Text('Custom Subnet...'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedSubnet == 'custom' || widget.existingSubnets.isEmpty)
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Device Address (e.g., 1.1.1.1)',
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
                )
              else ...[
                TextFormField(
                  controller: _deviceIndexController,
                  decoration: const InputDecoration(
                    labelText: 'Device Index',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a device index';
                    }
                    if (int.tryParse(value) == null ||
                        int.parse(value) < 1 ||
                        int.parse(value) > 255) {
                      return 'Please enter a valid device index (1-255)';
                    }
                    return null;
                  },
                ),
              ],
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
              final String deviceAddress;

              if (_selectedSubnet != 'custom' &&
                  _selectedSubnet != null &&
                  widget.existingSubnets.isNotEmpty) {
                deviceAddress =
                    '$_selectedSubnet.${_deviceIndexController.text}';
              } else {
                deviceAddress = _addressController.text;
              }

              final HelvarDevice device;

              switch (_deviceType) {
                case DeviceType.input:
                  device = HelvarDriverInputDevice(
                    deviceId: widget.nextDeviceId,
                    address: deviceAddress,
                    description: _descriptionController.text.isEmpty
                        ? 'Input Device ${widget.nextDeviceId}'
                        : _descriptionController.text,
                    props: '',
                  );
                  break;
                case DeviceType.emergency:
                  device = HelvarDriverEmergencyDevice(
                    deviceId: widget.nextDeviceId,
                    address: deviceAddress,
                    description: _descriptionController.text.isEmpty
                        ? 'Emergency Device ${widget.nextDeviceId}'
                        : _descriptionController.text,
                    emergency: true,
                  );
                  break;
                case DeviceType.output:
                  device = HelvarDriverOutputDevice(
                    deviceId: widget.nextDeviceId,
                    address: deviceAddress,
                    description: _descriptionController.text.isEmpty
                        ? 'Output Device ${widget.nextDeviceId}'
                        : _descriptionController.text,
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

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _deviceIndexController.dispose();
    super.dispose();
  }
}
