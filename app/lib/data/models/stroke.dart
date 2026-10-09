import 'dart:ui';
import 'package:flutter/foundation.dart';

@immutable
class Stroke {
  const Stroke(
      {required this.points,
      required this.color,
      required this.width,
      this.erase = false});
  final List<Offset> points;
  final Color color;
  final double width;
  final bool erase;
  Map<String, Object> toJson() => {
        'points': points
            .map((p) => {'x': p.dx.clamp(0.0, 1.0), 'y': p.dy.clamp(0.0, 1.0)})
            .toList(),
        'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
        'width': width,
        'erase': erase
      };
  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
      points: (json['points'] as List)
          .map((p) =>
              Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList(),
      color: Color(int.parse((json['color'] as String).replaceFirst('#', ''),
          radix: 16)),
      width: (json['width'] as num).toDouble(),
      erase: json['erase'] == true);
}
