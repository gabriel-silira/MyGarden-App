import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/trend_chart.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.navigate,
  });
  final GardenController controller;
  final VoidCallback onAdd;
  final ValueChanged<int> navigate;
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  int _hours = 24;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final cutoff = DateTime.now().subtract(Duration(hours: _hours));
    final readings = controller.readings
        .where((r) => !r.timestamp.isBefore(cutoff))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Monitoramento',
          subtitle:
              'Leituras simuladas ${controller.selectedPlant == null ? 'do seu jardim' : 'de ${controller.selectedPlant!.name}'}.',
          action: IconButton.filledTonal(
            tooltip: 'Atualizar leitura',
            onPressed: controller.busy || controller.selectedPlant == null
                ? null
                : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
        if (controller.selectedPlant == null)
          EmptyGarden(onAdd: widget.onAdd)
        else ...[
          if (controller.plants.length > 1)
            PlantSelector(controller: controller),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 24, 168, 720]
                .map(
                  (hours) => ChoiceChip(
                    label: Text(switch (hours) {
                      1 => '1 h',
                      24 => '24 h',
                      168 => '7 dias',
                      _ => '30 dias',
                    }),
                    selected: _hours == hours,
                    onSelected: (_) => setState(() => _hours = hours),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          ReadingSummary(controller: controller),
          const SizedBox(height: 18),
          _ChartPanel(
            title: 'Umidade do solo',
            value: controller.latest == null
                ? '—'
                : '${controller.latest!.moisture.round()}%',
            icon: Icons.water_drop_outlined,
            child: TrendChart(readings: readings),
          ),
          if (controller.temperatureEnabled) ...[
            const SizedBox(height: 16),
            _ChartPanel(
              title: 'Temperatura',
              value: controller.latest?.temperature == null
                  ? '—'
                  : '${numberLabel(controller.latest!.temperature!)} °C',
              icon: Icons.thermostat_outlined,
              child: TrendChart(readings: readings, temperature: true),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => widget.navigate(4),
                icon: const Icon(Icons.history),
                label: const Text('Histórico completo'),
              ),
              TextButton.icon(
                onPressed: () => widget.navigate(3),
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Irrigação'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Surface(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              key: const PageStorageKey('simulation-panel'),
              title: const Text('Experimentar cenários'),
              subtitle: const Text('Controle as condições do simulador'),
              leading: const Icon(Icons.science_outlined),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SimulationScenario.values
                      .map(
                        (scenario) => ChoiceChip(
                          label: Text(switch (scenario) {
                            SimulationScenario.balanced => 'Na faixa',
                            SimulationScenario.dry => 'Solo seco',
                            SimulationScenario.wet => 'Solo úmido',
                            SimulationScenario.disconnected => 'Sem conexão',
                            SimulationScenario.empty => 'Sem dados',
                          }),
                          selected: scenario == controller.scenario,
                          onSelected: controller.busy
                              ? null
                              : (_) => controller.setScenario(scenario),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cenários e faixas são demonstrativos. Os períodos filtram somente o histórico disponível nesta sessão.',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.value,
    required this.icon,
    required this.child,
  });
  final String title, value;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
