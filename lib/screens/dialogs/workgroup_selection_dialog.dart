import 'package:flutter/material.dart';
import 'package:grms_designer/utils/dialog_utils.dart';

class WorkgroupSelectionDialog extends StatefulWidget {
  const WorkgroupSelectionDialog({super.key, required this.workgroups});

  final List<String> workgroups;

  @override
  WorkgroupSelectionDialogState createState() =>
      WorkgroupSelectionDialogState();
}

class WorkgroupSelectionDialogState extends State<WorkgroupSelectionDialog> {
  String? selectedWorkgroup;
  final String addAllOption = '__ADD_ALL__';

  @override
  void initState() {
    super.initState();
    if (widget.workgroups.isNotEmpty) {
      selectedWorkgroup = widget.workgroups.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allOptions = [...widget.workgroups, addAllOption];

    return AlertDialog(
      title: const Text('Select Workgroup'),
      content: DropdownButton<String>(
        isExpanded: true,
        value: selectedWorkgroup ?? addAllOption,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedWorkgroup = newValue;
            });
          }
        },
        items: allOptions.map<DropdownMenuItem<String>>((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option == addAllOption ? 'Add All' : option,
              style: option == addAllOption
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
      actions: <Widget>[
        cancelAction(context),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(selectedWorkgroup);
          },
        ),
      ],
    );
  }
}
