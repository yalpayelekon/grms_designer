import 'package:flutter/material.dart';
import 'package:grms_designer/utils/ui_helpers.dart';

import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../actions.dart';

Future<void> showDeviceDirectProportionDialog(
  BuildContext context,
  HelvarDevice device,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb),
          SizedBox(width: 8),
          Text('Direct Proportion'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Proportion (-100 to 100)',
        ),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    try {
      final proportion = int.parse(result);
      if (proportion >= -100 && proportion <= 100) {
        performDeviceDirectProportion(context, device, proportion);
      } else {
        showSnackBarMsg(context, 'Proportion must be between -100 and 100');
      }
    } catch (e) {
      showSnackBarMsg(context, 'Invalid proportion value');
    }
  }
}

Future<void> showDeviceRecallSceneDialog(
  BuildContext context,
  HelvarDevice device,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb),
          SizedBox(width: 8),
          Text('Recall Scene'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Scene Number',
        ),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performDeviceRecallScene(context, device, int.parse(result));
  }
}

Future<void> showRecallSceneDialog(
  BuildContext context,
  HelvarGroup group,
  Workgroup workgroup,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero); // Allow popup menu to close

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/icons/helvar_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.lightbulb),
          ),
          const SizedBox(width: 8),
          const Text('Recall Scene'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performRecallScene(context, group, int.parse(result));
  }
}

Future<void> showStoreSceneDialog(
  BuildContext context,
  HelvarGroup group,
  Workgroup workgroup,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/icons/helvar_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.lightbulb),
          ),
          const SizedBox(width: 8),
          const Text('Store Scene'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performStoreScene(context, group, int.parse(result));
  }
}

Future<void> showDirectProportionDialog(
  BuildContext context,
  HelvarGroup group,
  Workgroup workgroup,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/icons/helvar_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.lightbulb),
          ),
          const SizedBox(width: 8),
          const Text('Direct Proportion'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performDirectProportion(context, group, int.parse(result));
  }
}

Future<void> showModifyProportionDialog(
  BuildContext context,
  HelvarGroup group,
  Workgroup workgroup,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/icons/helvar_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.lightbulb),
          ),
          const SizedBox(width: 8),
          const Text('Modify Proportion'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performModifyProportion(context, group, int.parse(result));
  }
}

Future<void> showDirectLevelDialog(
  BuildContext context,
  HelvarGroup group,
  Workgroup workgroup,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/icons/helvar_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.lightbulb),
          ),
          const SizedBox(width: 8),
          const Text('Direct Level'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    performDirectLevel(context, group, int.parse(result));
  }
}

Future<void> showDeviceDirectLevelDialog(
  BuildContext context,
  HelvarDevice device,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb),
          SizedBox(width: 8),
          Text('Direct Level'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Level (0-100)',
        ),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    try {
      final level = int.parse(result);
      if (level >= 0 && level <= 100) {
        performDeviceDirectLevel(context, device, level);
      } else {
        showSnackBarMsg(context, 'Level must be between 0 and 100');
      }
    } catch (e) {
      showSnackBarMsg(context, 'Invalid level value');
    }
  }
}

Future<void> showDeviceModifyProportionDialog(
  BuildContext context,
  HelvarDevice device,
) async {
  final TextEditingController controller = TextEditingController();

  await Future.delayed(Duration.zero);

  if (!context.mounted) return;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb),
          SizedBox(width: 8),
          Text('Modify Proportion'),
        ],
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Change amount (-100 to 100)',
        ),
      ),
      actions: [
        cancelAction(context),
        confirmActionWithText(context, controller.text),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    try {
      final change = int.parse(result);
      if (change >= -100 && change <= 100) {
        performDeviceModifyProportion(context, device, change);
      } else {
        showSnackBarMsg(context, 'Change amount must be between -100 and 100');
      }
    } catch (e) {
      showSnackBarMsg(context, 'Invalid change amount');
    }
  }
}
