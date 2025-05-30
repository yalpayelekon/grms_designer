import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

class HelvarGroup extends TreeNode {
  final String id;
  final String groupId;
  final String description;
  final String type;
  final int? lsig;
  final int? lsib1;
  final int? lsib2;
  final List<double> blockValues;
  final List<int> sceneTable;
  final double powerConsumption;
  final int powerPollingMinutes;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final String actionResult;
  final String lastMessage;
  final DateTime? lastMessageTime;

  HelvarGroup({
    required this.id,
    required this.groupId,
    this.description = '',
    this.type = 'Group',
    this.lsig,
    this.lsib1,
    this.lsib2,
    this.blockValues = const [],
    this.sceneTable = const [],
    this.powerConsumption = 0.0,
    this.powerPollingMinutes = 15,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.actionResult = '',
    this.lastMessage = '',
    this.lastMessageTime,
  }) : super(
         content: Text(description.isEmpty ? "Group $groupId" : description),
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
      type: json['type'] as String? ?? 'Group',
      lsig: json['lsig'] as int?,
      lsib1: json['lsib1'] as int?,
      lsib2: json['lsib2'] as int?,
      blockValues:
          (json['blockValues'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      sceneTable:
          (json['sceneTable'] as List?)?.map((e) => e as int).toList() ?? [],
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
      'type': type,
      'lsig': lsig,
      'lsib1': lsib1,
      'lsib2': lsib2,
      'blockValues': blockValues,
      'sceneTable': sceneTable,
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
    int? lsib1,
    int? lsib2,
    List<double>? blockValues,
    List<int>? sceneTable,
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
      type: type ?? this.type,
      lsig: lsig ?? this.lsig,
      lsib1: lsib1 ?? this.lsib1,
      lsib2: lsib2 ?? this.lsib2,
      blockValues: blockValues ?? this.blockValues,
      sceneTable: sceneTable ?? this.sceneTable,
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
