import 'dart:convert';
import 'package:flutter/material.dart';
import 'canvas_item.dart';

class Wiresheet {
  String id;
  String name;
  DateTime createdAt;
  DateTime modifiedAt;
  List<CanvasItem> canvasItems;
  Size canvasSize;
  Offset canvasOffset;

  Wiresheet({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<CanvasItem>? canvasItems,
    Size? canvasSize,
    Offset? canvasOffset,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        canvasItems = canvasItems ?? [],
        canvasSize = canvasSize ?? const Size(2000, 2000),
        canvasOffset = canvasOffset ?? const Offset(0, 0);

  void addItem(CanvasItem item) {
    canvasItems.add(item);
    modifiedAt = DateTime.now();
  }

  void removeItem(int index) {
    if (index >= 0 && index < canvasItems.length) {
      canvasItems.removeAt(index);
      modifiedAt = DateTime.now();
    }
  }

  void updateItem(int index, CanvasItem updatedItem) {
    if (index >= 0 && index < canvasItems.length) {
      canvasItems[index] = updatedItem;
      modifiedAt = DateTime.now();
    }
  }

  void updateCanvasSize(Size newSize) {
    canvasSize = newSize;
    modifiedAt = DateTime.now();
  }

  void updateCanvasOffset(Offset newOffset) {
    canvasOffset = newOffset;
    modifiedAt = DateTime.now();
  }

  factory Wiresheet.fromJson(Map<String, dynamic> json) {
    return Wiresheet(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      canvasItems: (json['canvasItems'] as List)
          .map((item) => CanvasItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      canvasSize: Size(
        (json['canvasSize']['width'] as num).toDouble(),
        (json['canvasSize']['height'] as num).toDouble(),
      ),
      canvasOffset: Offset(
        (json['canvasOffset']['dx'] as num).toDouble(),
        (json['canvasOffset']['dy'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'canvasItems': canvasItems.map((item) => item.toJson()).toList(),
      'canvasSize': {
        'width': canvasSize.width,
        'height': canvasSize.height,
      },
      'canvasOffset': {
        'dx': canvasOffset.dx,
        'dy': canvasOffset.dy,
      },
    };
  }

  Wiresheet copy() {
    return Wiresheet(
      id: id,
      name: name,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      canvasItems: List.from(canvasItems),
      canvasSize: canvasSize,
      canvasOffset: canvasOffset,
    );
  }
}
