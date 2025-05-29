class OutputPoint {
  final String name;
  final String function;
  final int pointId;
  final String pointType;
  dynamic value;

  OutputPoint({
    required this.name,
    required this.function,
    required this.pointId,
    required this.pointType,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'pointId': pointId,
      'pointType': pointType,
      'value': value,
    };
  }

  factory OutputPoint.fromJson(Map<String, dynamic> json) {
    return OutputPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      pointId: json['pointId'] as int,
      pointType: json['pointType'] as String,
      value: json['value'],
    );
  }
}
