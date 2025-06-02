import 'package:flutter/material.dart';

const double rowHeight = 22.0;

void showSnackBarMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget buildInfoRow(String label, String value, {double? width}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width ?? 220,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

TextButton cancelAction(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const Text('Cancel'),
  );
}

TextButton closeAction(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const Text('Close'),
  );
}

TextButton confirmAction(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(true),
    child: const Text('OK'),
  );
}

TextButton confirmActionWithText(BuildContext context, String text) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(text),
    child: const Text('OK'),
  );
}
