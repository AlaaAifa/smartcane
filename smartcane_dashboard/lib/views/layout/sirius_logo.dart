import 'package:flutter/material.dart';

class SiriusLogo extends StatelessWidget {
  final double size;
  const SiriusLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: SiriusIconPainter()),
    );
  }
}

class SiriusIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orangePaint = Paint()..color = const Color(0xFFf5a623)..strokeWidth = 3.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final bluePaint = Paint()..color = const Color(0xFF4fb3ff)..style = PaintingStyle.fill;
    final yellowPaint = Paint()..color = const Color(0xFFffd84a)..style = PaintingStyle.fill;

    final path = Path();
    // Vertical body
    path.moveTo(center.dx, center.dy - 2);
    path.lineTo(center.dx, center.dy + 12);
    // Bottom curve
    path.addArc(Rect.fromLTWH(center.dx - 8, center.dy + 4, 8, 8), 0, 3.14);
    
    // Y branches
    canvas.drawLine(center, Offset(center.dx - 12, center.dy - 12), orangePaint);
    canvas.drawLine(center, Offset(center.dx + 12, center.dy - 12), orangePaint);
    canvas.drawPath(path, orangePaint);
    
    // Central node
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFf5a623));
    
    // Left circle (blue)
    canvas.drawCircle(Offset(center.dx - 12, center.dy - 12), 4, bluePaint);
    // Right circle (yellow)
    canvas.drawCircle(Offset(center.dx + 12, center.dy - 12), 4, yellowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
