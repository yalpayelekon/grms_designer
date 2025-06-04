import 'package:grms_designer/models/helvar_models/workgroup.dart';

class OutputPoint {
  final String name;
  final String function;
  final int pointId;
  final String pointType;
  final PointPollingRate pollingRate;
  dynamic value;

  OutputPoint({
    required this.name,
    required this.function,
    required this.pointId,
    required this.pointType,
    this.pollingRate = PointPollingRate.normal,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'pointId': pointId,
      'pointType': pointType,
      'pollingRate': pollingRate.name,
      'value': value,
    };
  }

  factory OutputPoint.fromJson(Map<String, dynamic> json) {
    return OutputPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      pointId: json['pointId'] as int,
      pointType: json['pointType'] as String,
      pollingRate: json['pollingRate'] != null
          ? PointPollingRate.fromString(json['pollingRate'] as String)
          : PointPollingRate.normal,
      value: json['value'],
    );
  }

  OutputPoint copyWith({
    String? name,
    String? function,
    int? pointId,
    String? pointType,
    PointPollingRate? pollingRate,
    dynamic value,
  }) {
    return OutputPoint(
      name: name ?? this.name,
      function: function ?? this.function,
      pointId: pointId ?? this.pointId,
      pointType: pointType ?? this.pointType,
      pollingRate: pollingRate ?? this.pollingRate,
      value: value ?? this.value,
    );
  }
}
