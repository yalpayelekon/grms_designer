import 'package:flutter/material.dart';
import 'package:grms_designer/utils/dialog_utils.dart';

class PasteSpecialDialog extends StatefulWidget {
  final Function(int, bool, bool) onPasteConfirmed;

  const PasteSpecialDialog({super.key, required this.onPasteConfirmed});

  @override
  State<PasteSpecialDialog> createState() => _PasteSpecialDialogState();
}

class _PasteSpecialDialogState extends State<PasteSpecialDialog> {
  int numberOfCopies = 1;
  bool keepAllLinks = true;
  bool keepAllRelations = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.copy, size: 20),
          SizedBox(width: 8),
          Text('Paste Special'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Number of copies'),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: numberOfCopies.toString(),
                  ),
                  onChanged: (value) {
                    int? parsedValue = int.tryParse(value);
                    if (parsedValue != null && parsedValue > 0) {
                      setState(() {
                        numberOfCopies = parsedValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: keepAllLinks,
                onChanged: (value) {
                  setState(() {
                    keepAllLinks = value ?? true;
                  });
                },
              ),
              const Text('Keep all links'),
            ],
          ),
        ],
      ),
      actions: [
        cancelAction(context),
        TextButton(
          onPressed: () {
            widget.onPasteConfirmed(
              numberOfCopies,
              keepAllLinks,
              keepAllRelations,
            );
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
