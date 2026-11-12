import 'package:flutter/material.dart';

import '../theme/garden_theme.dart';

class GardenBackdrop extends StatelessWidget {
  const GardenBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _Waves(GardenTheme.isDark(context)), child: child);
}

class _Waves extends CustomPainter {
  const _Waves(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF001B11), const Color(0xFF002015)]
              : [const Color(0xFFF7FCF2), const Color(0xFFEAF8E0)],
        ).createShader(rect),
    );
    final wave = Path()
      ..moveTo(size.width * .44, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .48)
      ..cubicTo(
        size.width * .72,
        size.height * .29,
        size.width * .62,
        size.height * .52,
        size.width * .25,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .8,
        size.height * .27,
        size.width * .45,
        size.height * .1,
        size.width * .44,
        0,
      )
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..color = (dark ? const Color(0xFF07512D) : const Color(0xFFB9ED97))
            .withValues(alpha: dark ? .34 : .28),
    );
    final lower = Path()
      ..moveTo(0, size.height * .79)
      ..cubicTo(
        size.width * .35,
        size.height * .92,
        size.width * .68,
        size.height * .62,
        size.width,
        size.height * .72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      lower,
      Paint()
        ..color = (dark ? const Color(0xFF06462B) : const Color(0xFFC2EFA6))
            .withValues(alpha: .35),
    );
  }

  @override
  bool shouldRepaint(_Waves oldDelegate) => oldDelegate.dark != dark;
}
