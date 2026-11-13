import 'package:flutter/material.dart';

import '../theme/garden_theme.dart';

/// Vector mark follows the two leaves and earth arc of the supplied brand.
class MintSymbol extends StatelessWidget {
  const MintSymbol({
    super.key,
    this.size = 100,
    this.color,
    this.label = 'Símbolo MyGarden',
  });
  final double size;
  final Color? color;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _MintPainter(color)),
  );
}

class _MintPainter extends CustomPainter {
  const _MintPainter(this.color);
  final Color? color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint();
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD9FF81), Color(0xFF8CDD18), Color(0xFF087421)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    }
    final right = Path()
      ..moveTo(48, 72)
      ..cubicTo(26, 44, 58, 11, 93, 10)
      ..cubicTo(89, 49, 78, 70, 55, 68)
      ..cubicTo(60, 48, 71, 33, 78, 25)
      ..cubicTo(59, 41, 51, 61, 46, 82)
      ..lineTo(39, 82)
      ..cubicTo(42, 72, 44, 69, 48, 62)
      ..close();
    final left = Path()
      ..moveTo(35, 68)
      ..cubicTo(17, 70, 9, 47, 7, 33)
      ..cubicTo(26, 31, 46, 42, 43, 61)
      ..cubicTo(33, 50, 24, 44, 18, 42)
      ..cubicTo(26, 52, 31, 60, 35, 68)
      ..close();
    final ground = Path()
      ..moveTo(15, 91)
      ..quadraticBezierTo(48, 67, 85, 91)
      ..quadraticBezierTo(49, 79, 15, 91)
      ..close();
    canvas.drawPath(right, paint);
    canvas.drawPath(left, paint);
    canvas.drawPath(ground, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MintPainter oldDelegate) => color != oldDelegate.color;
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'MyGarden',
    excludeSemantics: true,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MintSymbol(size: 32),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'My'),
                TextSpan(
                  text: 'Garden',
                  style: TextStyle(
                    color: GardenTheme.isDark(context)
                        ? GardenTheme.lime
                        : const Color(0xFF155C16),
                  ),
                ),
              ],
            ),
            textScaler: TextScaler.noScaling,
            style: Theme.of(context).textTheme.titleLarge!
                .copyWith(fontSize: 23, letterSpacing: -.8),
          ),
        ],
      ),
    ),
  );
}

class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, required this.dark, this.size = 64});
  final bool dark;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .24),
    child: SizedBox.square(
      dimension: size,
      child: OverflowBox(
        // The originals include a black outer margin and a baked-in border.
        // Crop inside that border; the widget supplies the visible corners.
        maxWidth: size * 1.26,
        maxHeight: size * 1.26,
        child: Image.asset(
          'assets/brand/icon-${dark ? 'dark' : 'light'}.png',
          width: size * 1.26,
          height: size * 1.26,
          cacheWidth: (size * 1.26 * MediaQuery.devicePixelRatioOf(context))
              .ceil(),
          semanticLabel: 'Ícone MyGarden ${dark ? 'escuro' : 'claro'}',
        ),
      ),
    ),
  );
}
