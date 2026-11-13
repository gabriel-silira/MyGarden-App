import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'garden_widgets.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.readings,
    this.temperature = false,
  });
  final List<SensorReading> readings;
  final bool temperature;
  @override
  Widget build(BuildContext context) {
    final usable = readings
        .where((r) => !temperature || r.temperature != null)
        .toList();
    if (usable.length < 2) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'A evolução aparece com pelo menos duas leituras.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final values = usable
        .map((r) => temperature ? r.temperature! : r.moisture)
        .toList();
    final min = temperature
        ? (values.reduce((a, b) => a < b ? a : b) - 2).floorToDouble()
        : 0.0;
    final max = temperature
        ? (values.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble()
        : 100.0;
    final unit = temperature ? '°C' : '%';
    final c = Theme.of(context).colorScheme;
    final axisWidth = MediaQuery.textScalerOf(context).scale(56);
    final chartHeight = MediaQuery.textScalerOf(context).scale(150);
    return Semantics(
      label:
          '${temperature ? 'Temperatura' : 'Umidade'}, ${usable.length} leituras simuladas. '
          'De ${values.first.toStringAsFixed(1)} a ${values.last.toStringAsFixed(1)} $unit. '
          'Valores detalhados na lista de leituras.',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: axisWidth,
                height: chartHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    5,
                    (i) => Text(
                      '${(max - (max - min) * i / 4).round()}$unit',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: chartHeight,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      readings: usable,
                      temperature: temperature,
                      min: min,
                      max: max,
                      line: c.primary,
                      grid: c.outlineVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: axisWidth),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    dateLabel(usable.first.timestamp),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    clockLabel(usable.last.timestamp),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.readings,
    required this.temperature,
    required this.min,
    required this.max,
    required this.line,
    required this.grid,
  });
  final List<SensorReading> readings;
  final bool temperature;
  final double min, max;
  final Color line, grid;
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = 5 + (size.height - 10) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path();
    final start = readings.first.timestamp.millisecondsSinceEpoch;
    // Avoid bitwise bounds: JavaScript bit operations use 32-bit integers.
    final elapsed = readings.last.timestamp.millisecondsSinceEpoch - start;
    final duration = elapsed > 0 ? elapsed : 1;
    var endpoint = Offset.zero;
    for (var i = 0; i < readings.length; i++) {
      final value = temperature
          ? readings[i].temperature!
          : readings[i].moisture;
      final x =
          (readings[i].timestamp.millisecondsSinceEpoch - start) /
          duration *
          size.width;
      final y =
          size.height - 5 - (value - min) / (max - min) * (size.height - 10);
      endpoint = Offset(x, y);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(endpoint.dx, size.height - 5)
      ..lineTo(0, size.height - 5)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: .20), line.withValues(alpha: .01)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(endpoint, 5, Paint()..color = line);
    canvas.drawCircle(endpoint, 2.5, Paint()..color = const Color(0xFFE7FFD1));
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => true;
}
