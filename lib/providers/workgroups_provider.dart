import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workgroup.dart';

class WorkgroupsNotifier extends StateNotifier<List<Workgroup>> {
  WorkgroupsNotifier() : super([]);

  void addWorkgroup(Workgroup workgroup) {
    state = [...state, workgroup];
  }

  void removeWorkgroup(String id) {
    state = state.where((wg) => wg.id != id).toList();
  }

  void updateWorkgroup(Workgroup updatedWorkgroup) {
    state = state
        .map((wg) => wg.id == updatedWorkgroup.id ? updatedWorkgroup : wg)
        .toList();
  }

  void clearWorkgroups() {
    state = [];
  }
}

final workgroupsProvider =
    StateNotifierProvider<WorkgroupsNotifier, List<Workgroup>>((ref) {
  return WorkgroupsNotifier();
});
