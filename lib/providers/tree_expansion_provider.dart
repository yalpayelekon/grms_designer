import 'package:flutter_riverpod/flutter_riverpod.dart';

class TreeExpansionState {
  final Set<String> expandedNodes;
  final Set<String> newlyAddedNodes;

  TreeExpansionState({
    required this.expandedNodes,
    required this.newlyAddedNodes,
  });

  TreeExpansionState copyWith({
    Set<String>? expandedNodes,
    Set<String>? newlyAddedNodes,
  }) {
    return TreeExpansionState(
      expandedNodes: expandedNodes ?? this.expandedNodes,
      newlyAddedNodes: newlyAddedNodes ?? this.newlyAddedNodes,
    );
  }
}

class TreeExpansionNotifier extends StateNotifier<TreeExpansionState> {
  TreeExpansionNotifier()
      : super(TreeExpansionState(
          expandedNodes: <String>{},
          newlyAddedNodes: <String>{},
        ));

  bool isNodeExpanded(String nodeId) {
    return state.expandedNodes.contains(nodeId);
  }

  void toggleNodeExpansion(String nodeId) {
    final newExpandedNodes = Set<String>.from(state.expandedNodes);

    if (newExpandedNodes.contains(nodeId)) {
      newExpandedNodes.remove(nodeId);
    } else {
      newExpandedNodes.add(nodeId);
    }

    state = state.copyWith(expandedNodes: newExpandedNodes);
  }

  void setNodeExpansion(String nodeId, bool expanded) {
    final newExpandedNodes = Set<String>.from(state.expandedNodes);

    if (expanded) {
      newExpandedNodes.add(nodeId);
    } else {
      newExpandedNodes.remove(nodeId);
    }

    state = state.copyWith(expandedNodes: newExpandedNodes);
  }

  void markNodesAsNewlyAdded(List<String> nodeIds) {
    final newNewlyAddedNodes = Set<String>.from(state.newlyAddedNodes);
    newNewlyAddedNodes.addAll(nodeIds);

    state = state.copyWith(newlyAddedNodes: newNewlyAddedNodes);
  }

  void clearNewlyAddedNodes() {
    state = state.copyWith(newlyAddedNodes: <String>{});
  }

  void resetExpansionState() {
    state = TreeExpansionState(
      expandedNodes: <String>{},
      newlyAddedNodes: <String>{},
    );
  }

  bool getInitialExpansionState(String nodeId) {
    if (state.newlyAddedNodes.contains(nodeId)) {
      return false;
    }

    return state.expandedNodes.contains(nodeId);
  }

  void updateMultipleNodes(Map<String, bool> nodeStates) {
    final newExpandedNodes = Set<String>.from(state.expandedNodes);

    nodeStates.forEach((nodeId, expanded) {
      if (expanded) {
        newExpandedNodes.add(nodeId);
      } else {
        newExpandedNodes.remove(nodeId);
      }
    });

    state = state.copyWith(expandedNodes: newExpandedNodes);
  }
}

final treeExpansionProvider =
    StateNotifierProvider<TreeExpansionNotifier, TreeExpansionState>((ref) {
  return TreeExpansionNotifier();
});
