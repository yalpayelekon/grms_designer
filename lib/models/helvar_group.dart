import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

class HelvarGroup extends TreeNode {
  final String id;
  final String groupId;
  final String description;
  final String type;
  final int? lsig; // Light Scene In Group
  final int powerPollingMinutes;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;

  HelvarGroup({
    required this.id,
    required this.groupId,
    this.description = '',
    this.type = 'Group',
    this.lsig,
    this.powerPollingMinutes = 15,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
  }) : super(
            content:
                Text(description.isEmpty ? "Group $groupId" : description));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HelvarGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory HelvarGroup.fromJson(Map<String, dynamic> json) {
    return HelvarGroup(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'Group',
      lsig: json['lsig'] as int?,
      powerPollingMinutes: json['powerPollingMinutes'] as int? ?? 15,
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'type': type,
      'lsig': lsig,
      'powerPollingMinutes': powerPollingMinutes,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
    };
  }
}
