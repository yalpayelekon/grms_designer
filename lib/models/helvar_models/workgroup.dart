import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'helvar_router.dart';
import 'helvar_group.dart';

enum PointPollingRate {
  fast,
  normal,
  slow;

  String get displayName {
    switch (this) {
      case PointPollingRate.fast:
        return 'Fast';
      case PointPollingRate.normal:
        return 'Normal';
      case PointPollingRate.slow:
        return 'Slow';
    }
  }

  static PointPollingRate fromString(String value) {
    return PointPollingRate.values.firstWhere(
      (rate) => rate.name == value,
      orElse: () => PointPollingRate.normal,
    );
  }
}

class PollingRateDuration {
  final int hours;
  final int minutes;
  final int seconds;

  PollingRateDuration({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  Duration get duration =>
      Duration(hours: hours, minutes: minutes, seconds: seconds);

  String get displayName =>
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    return {'hours': hours, 'minutes': minutes, 'seconds': seconds};
  }

  factory PollingRateDuration.fromJson(Map<String, dynamic> json) {
    return PollingRateDuration(
      hours: json['hours'] as int? ?? 0,
      minutes: json['minutes'] as int? ?? 0,
      seconds: json['seconds'] as int? ?? 0,
    );
  }

  PollingRateDuration copyWith({int? hours, int? minutes, int? seconds}) {
    return PollingRateDuration(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
    );
  }
}

class Workgroup extends TreeNode {
  final String id;
  final String description;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final bool pollEnabled;
  final DateTime? lastPollTime;

  final PollingRateDuration fastRate;
  final PollingRateDuration normalRate;
  final PollingRateDuration slowRate;

  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.pollEnabled = false,
    this.lastPollTime,
    PollingRateDuration? fastRate,
    PollingRateDuration? normalRate,
    PollingRateDuration? slowRate,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) : fastRate =
           fastRate ?? PollingRateDuration(hours: 0, minutes: 0, seconds: 10),
       normalRate =
           normalRate ?? PollingRateDuration(hours: 0, minutes: 1, seconds: 0),
       slowRate =
           slowRate ?? PollingRateDuration(hours: 0, minutes: 5, seconds: 0),
       routers = routers ?? [],
       groups = groups ?? [];

  void addRouter(HelvarRouter router) {
    routers.add(router);
  }

  void removeRouter(HelvarRouter router) {
    routers.remove(router);
  }

  void addGroup(HelvarGroup group) {
    groups.add(group);
  }

  void removeGroup(HelvarGroup group) {
    groups.remove(group);
  }

  Duration getDurationForRate(PointPollingRate rate) {
    switch (rate) {
      case PointPollingRate.fast:
        return fastRate.duration;
      case PointPollingRate.normal:
        return normalRate.duration;
      case PointPollingRate.slow:
        return slowRate.duration;
    }
  }

  Workgroup copyWith({
    String? id,
    String? description,
    String? networkInterface,
    int? groupPowerPollingMinutes,
    String? gatewayRouterIpAddress,
    bool? refreshPropsAfterAction,
    bool? pollEnabled,
    DateTime? lastPollTime,
    PollingRateDuration? fastRate,
    PollingRateDuration? normalRate,
    PollingRateDuration? slowRate,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) {
    return Workgroup(
      id: id ?? this.id,
      description: description ?? this.description,
      gatewayRouterIpAddress:
          gatewayRouterIpAddress ?? this.gatewayRouterIpAddress,
      refreshPropsAfterAction:
          refreshPropsAfterAction ?? this.refreshPropsAfterAction,
      pollEnabled: pollEnabled ?? this.pollEnabled,
      lastPollTime: lastPollTime ?? this.lastPollTime,
      fastRate: fastRate ?? this.fastRate,
      normalRate: normalRate ?? this.normalRate,
      slowRate: slowRate ?? this.slowRate,
      routers: routers ?? this.routers,
      groups: groups ?? this.groups,
    );
  }

  factory Workgroup.fromJson(Map<String, dynamic> json) {
    return Workgroup(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
      pollEnabled: json['pollEnabled'] as bool? ?? false,
      lastPollTime: json['lastPollTime'] != null
          ? DateTime.parse(json['lastPollTime'] as String)
          : null,
      fastRate: json['fastRate'] != null
          ? PollingRateDuration.fromJson(json['fastRate'])
          : null,
      normalRate: json['normalRate'] != null
          ? PollingRateDuration.fromJson(json['normalRate'])
          : null,
      slowRate: json['slowRate'] != null
          ? PollingRateDuration.fromJson(json['slowRate'])
          : null,
      routers: (json['routers'] as List?)
          ?.map((routerJson) => HelvarRouter.fromJson(routerJson))
          .toList(),
      groups:
          (json['groups'] as List?)
              ?.map((groupJson) => HelvarGroup.fromJson(groupJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
      'pollEnabled': pollEnabled,
      'lastPollTime': lastPollTime?.toIso8601String(),
      'fastRate': fastRate.toJson(),
      'normalRate': normalRate.toJson(),
      'slowRate': slowRate.toJson(),
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }
}
