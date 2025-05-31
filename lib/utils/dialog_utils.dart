import 'package:flutter/material.dart';

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
