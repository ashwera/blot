import 'package:flutter/material.dart';
import '../../data/models/stroke.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas(
      {super.key,
      required this.strokes,
      required this.onStroke,
      this.color = const Color(0xff302b3d),
      this.brush = 5,
      this.eraser = false,
      this.readOnly = false});
  final List<Stroke> strokes;
  final ValueChanged<Stroke> onStroke;
  final Color color;
  final double brush;
  final bool eraser, readOnly;
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Stroke? current;
  Offset _normalized(Offset p, Size s) =>
      Offset((p.dx / s.width).clamp(0, 1), (p.dy / s.height).clamp(0, 1));
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: widget.readOnly
                ? null
                : (d) => setState(() => current = Stroke(
                    points: [_normalized(d.localPosition, size)],
                    color: widget.color,
                    width: widget.brush,
                    erase: widget.eraser)),
            onPanUpdate: widget.readOnly
                ? null
                : (d) => setState(() {
                      final s = current!;
                      current = Stroke(points: [
                        ...s.points,
                        _normalized(d.localPosition, size)
                      ], color: s.color, width: s.width, erase: s.erase);
                    }),
            onPanEnd: widget.readOnly
                ? null
                : (_) {
                    if (current != null) widget.onStroke(current!);
                    setState(() => current = null);
                  },
            child: CustomPaint(
                size: size,
                painter: _Painter(
                    [...widget.strokes, if (current != null) current!])));
      });
}

class _Painter extends CustomPainter {
  _Painter(this.strokes);
  final List<Stroke> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xfffffdf8), BlendMode.src);
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.erase ? const Color(0xfffffdf8) : stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final pts = stroke.points
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      if (pts.length == 1) {
        canvas.drawCircle(
            pts.first, stroke.width / 2, paint..style = PaintingStyle.fill);
      } else {
        for (var i = 1; i < pts.length; i++) {
          final mid = Offset(
              (pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
          path.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
        }
        path.lineTo(pts.last.dx, pts.last.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      !identical(old.strokes, strokes) || old.strokes.length != strokes.length;
}
