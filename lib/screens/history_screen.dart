import 'package:flutter/material.dart';

import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/trend_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
    required this.onAdd,
  });
  final GardenController controller;
  final VoidCallback onAdd;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _hours = 24;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final cutoff = DateTime.now().subtract(Duration(hours: _hours));
    final readings = controller.readings
        .where((r) => !r.timestamp.isBefore(cutoff))
        .toList();
    final events = controller.events
        .where((e) => !e.timestamp.isBefore(cutoff))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Histórico',
          subtitle: 'Pequenas mudanças contam a história do seu jardim.',
        ),
        if (controller.selectedPlant == null)
          EmptyGarden(onAdd: widget.onAdd)
        else ...[
          PlantSelector(controller: controller),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 24, 168]
                .map(
                  (hours) => ChoiceChip(
                    label: Text(switch (hours) {
                      1 => 'Última hora',
                      24 => '24 horas',
                      _ => '7 dias',
                    }),
                    selected: _hours == hours,
                    onSelected: (_) => setState(() => _hours = hours),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Notice(
            'Dados demonstrativos. Leituras e eventos são mantidos apenas nesta sessão; '
            'o histórico inicial contém 24 leituras fictícias.',
          ),
          const SizedBox(height: 20),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Umidade do solo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TrendChart(readings: readings),
              ],
            ),
          ),
          if (controller.temperatureEnabled) ...[
            const SizedBox(height: 20),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperatura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  TrendChart(readings: readings, temperature: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Eventos de irrigação',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          EventList(events: events),
          const SizedBox(height: 24),
          Text(
            'Leituras do período (${readings.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (readings.isEmpty)
            const Text(
              'Nenhuma leitura neste período. Atualize em Monitoramento.',
            ),
          ...readings.reversed
              .take(50)
              .map(
                (r) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sensors),
                      title: Text(
                        '${r.moisture.round()}% de umidade${controller.temperatureEnabled && r.temperature != null ? ' • ${r.temperature!.toStringAsFixed(1)} °C' : ''}',
                      ),
                      subtitle: Text('${dateLabel(r.timestamp)} • simulado'),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
          if (readings.length > 50)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Exibindo as 50 leituras mais recentes. O gráfico inclui todas as leituras do período.',
              ),
            ),
        ],
      ],
    );
  }
}
