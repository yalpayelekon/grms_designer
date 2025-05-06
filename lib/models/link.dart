class Link {
  final String id;
  final String sourceItemId;
  final String targetItemId;
  final String sourcePortId;
  final String targetPortId;
  final LinkType type;

  Link({
    required this.id,
    required this.sourceItemId,
    required this.targetItemId,
    required this.sourcePortId,
    required this.targetPortId,
    this.type = LinkType.dataFlow,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceItemId': sourceItemId,
      'targetItemId': targetItemId,
      'sourcePortId': sourcePortId,
      'targetPortId': targetPortId,
      'type': type.toString().split('.').last,
    };
  }

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: json['id'],
      sourceItemId: json['sourceItemId'],
      targetItemId: json['targetItemId'],
      sourcePortId: json['sourcePortId'],
      targetPortId: json['targetPortId'],
      type: LinkType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => LinkType.dataFlow,
      ),
    );
  }
}

enum LinkType {
  dataFlow,
  controlFlow,
}

class Port {
  final String id;
  final PortType type;
  final String name;
  final bool isInput;

  Port({
    required this.id,
    required this.type,
    required this.name,
    required this.isInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'isInput': isInput,
    };
  }

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      id: json['id'],
      type: PortType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PortType.any,
      ),
      name: json['name'],
      isInput: json['isInput'],
    );
  }
}

enum PortType {
  number,
  string,
  boolean,
  any,
}
