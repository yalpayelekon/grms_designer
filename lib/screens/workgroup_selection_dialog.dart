import 'package:flutter/material.dart';

class WorkgroupSelectionDialog extends StatefulWidget {
  const WorkgroupSelectionDialog({Key? key, required this.workgroups})
      : super(key: key);

  final List<String> workgroups;

  @override
  _WorkgroupSelectionDialogState createState() =>
      _WorkgroupSelectionDialogState();
}

class _WorkgroupSelectionDialogState extends State<WorkgroupSelectionDialog> {
  String? selectedWorkgroup;

  @override
  void initState() {
    super.initState();
    if (widget.workgroups.isNotEmpty) {
      selectedWorkgroup = widget.workgroups.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Workgroups Discovered'),
      content: DropdownButton<String>(
        isExpanded: true,
        value: selectedWorkgroup,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedWorkgroup = newValue;
            });
          }
        },
        items:
            widget.workgroups.map<DropdownMenuItem<String>>((String workgroup) {
          return DropdownMenuItem<String>(
            value: workgroup,
            child: Text(workgroup),
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
            Navigator.of(context).pop(selectedWorkgroup);
          },
        ),
      ],
    );
  }
}
