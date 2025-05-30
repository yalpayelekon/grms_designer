// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

String getSceneDisplayName(int scene) {
  switch (scene) {
    case 128:
      return 'Scene $scene (Off)';
    case 129:
      return 'Scene $scene (Min Level)';
    case 130:
      return 'Scene $scene (Max Level)';
    case 137:
      return 'Scene $scene (0%)';
    case 138:
      return 'Scene $scene (1%)';
    case 237:
      return 'Scene $scene (100%)';
    default:
      if (scene >= 137 && scene <= 237) {
        final percentage = scene - 137;
        return 'Scene $scene ($percentage%)';
      }
      return 'Scene $scene';
  }
}

Color getSceneChipColor(int scene) {
  switch (scene) {
    case 128: // Off
      return Colors.red.withOpacity(0.1);
    case 129: // Min Level
      return Colors.orange.withOpacity(0.1);
    case 130: // Max Level
      return Colors.green.withOpacity(0.1);
    default:
      if (scene >= 137 && scene <= 237) {
        // Percentage scenes
        return Colors.purple.withOpacity(0.1);
      }
      return Colors.blue.withOpacity(0.1);
  }
}
