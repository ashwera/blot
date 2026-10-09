import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:blot/data/models/stroke.dart';

void main() {
  test('stroke serializes normalized coordinates and restores style', () {
    const stroke = Stroke(
        points: [Offset(.25, .75)],
        color: Color(0xffef6c45),
        width: 8,
        erase: true);
    final copy = Stroke.fromJson(stroke.toJson());
    expect(copy.points.single, const Offset(.25, .75));
    expect(copy.color, const Color(0xffef6c45));
    expect(copy.width, 8);
    expect(copy.erase, true);
  });
}
