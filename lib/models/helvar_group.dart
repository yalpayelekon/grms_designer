// lib/models/helvar_group.dart
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'helvar_node.dart';

class HelvarGroup extends TreeViewNode {
  final String groupId;
  final String description;
  final int? lsig;
  final List<double> blockValues;
  final double powerConsumption;
  final int powerPollingMinutes;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final String actionResult;
  final String lastMessage;
  final DateTime? lastMessageTime;

  HelvarGroup({
    required super.id,
    required this.groupId,
    this.description = '',
    this.lsig,
    this.blockValues = const [],
    this.powerConsumption = 0.0,
    this.powerPollingMinutes = 15,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.actionResult = '',
    this.lastMessage = '',
    this.lastMessageTime,
    super.children,
  }) : super(
          name: description.isEmpty ? "Group $groupId" : description,
          nodeType: TreeViewNodeType.group,
        );

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
      lsig: json['lsig'] as int?,
      blockValues: (json['blockValues'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      powerConsumption: (json['powerConsumption'] as num?)?.toDouble() ?? 0.0,
      powerPollingMinutes: json['powerPollingMinutes'] as int? ?? 15,
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
      actionResult: json['actionResult'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'type': nodeType,
      'lsig': lsig,
      'blockValues': blockValues,
      'powerConsumption': powerConsumption,
      'powerPollingMinutes': powerPollingMinutes,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
      'actionResult': actionResult,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }

  HelvarGroup copyWith({
    String? id,
    String? groupId,
    String? description,
    String? type,
    int? lsig,
    List<double>? blockValues,
    double? powerConsumption,
    int? powerPollingMinutes,
    String? gatewayRouterIpAddress,
    bool? refreshPropsAfterAction,
    String? actionResult,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return HelvarGroup(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      lsig: lsig ?? this.lsig,
      blockValues: blockValues ?? this.blockValues,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      powerPollingMinutes: powerPollingMinutes ?? this.powerPollingMinutes,
      gatewayRouterIpAddress:
          gatewayRouterIpAddress ?? this.gatewayRouterIpAddress,
      refreshPropsAfterAction:
          refreshPropsAfterAction ?? this.refreshPropsAfterAction,
      actionResult: actionResult ?? this.actionResult,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
