import 'package:flutter/material.dart';
import 'package:grms_designer/utils/dialog_utils.dart';

import '../../models/helvar_models/helvar_router.dart';

Widget buildRouterSelectionDialog(
  List<Map<String, dynamic>> routersInfo,
  Set<int> selectedIndices,
) {
  return StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        title: const Text('Connect to Routers'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: routersInfo.length,
                  itemBuilder: (context, index) {
                    final routerInfo = routersInfo[index];
                    final router = routerInfo['router'] as HelvarRouter;

                    return CheckboxListTile(
                      title: Text(router.description),
                      subtitle: Text(
                        '${routerInfo['workgroup']} - ${router.ipAddress}',
                      ),
                      value: selectedIndices.contains(index),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            selectedIndices.add(index);
                          } else {
                            selectedIndices.remove(index);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (selectedIndices.length == routersInfo.length) {
                          selectedIndices.clear();
                        } else {
                          selectedIndices.clear();
                          selectedIndices.addAll(
                            List.generate(routersInfo.length, (i) => i),
                          );
                        }
                      });
                    },
                    child: Text(
                      selectedIndices.length == routersInfo.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(selectedIndices.toList()),
            child: const Text('Connect'),
          ),
        ],
      );
    },
  );
}
