import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/plant_tile.dart';
import '../widgets/trend_chart.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.controller,
    required this.navigate,
  });
  final GardenController controller;
  final ValueChanged<int> navigate;
  @override
  Widget build(BuildContext context) {
    final plant = controller.selectedPlant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Olá!',
          subtitle: '${controller.gardenName}, mais perto de você.',
        ),
        if (plant == null)
          EmptyGarden(onAdd: () => navigate(1))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 700 &&
                  MediaQuery.sizeOf(context).width >
                      MediaQuery.sizeOf(context).height &&
                  MediaQuery.textScalerOf(context).scale(14) < 21;
              final main = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlantTile(plant: plant, onTap: () => navigate(2)),
                  const SizedBox(height: 14),
                  ReadingSummary(controller: controller),
                  const SizedBox(height: 14),
                  _WateringCard(controller: controller, navigate: navigate),
                  const SizedBox(height: 20),
                  Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Umidade do solo',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (controller.latest != null)
                              Text(
                                '${controller.latest!.moisture.round()}%',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TrendChart(readings: controller.readings),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => navigate(4),
                            child: const Text('Ver histórico'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (!wide) return main;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: main),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 5,
                    child: Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Meu jardim',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton.filled(
                                tooltip: 'Abrir jardim',
                                onPressed: () => navigate(1),
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                          Text(
                            '${controller.plants.length} ${controller.plants.length == 1 ? 'planta cadastrada' : 'plantas cadastradas'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          ...controller.plants.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: controller.busy
                                    ? null
                                    : () {
                                        controller.selectPlant(p.id);
                                        navigate(2);
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      ExcludeSemantics(
                                        child: PlantArtwork(plant: p, size: 58),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            if (p.species.isNotEmpty)
                                              Text(
                                                p.species,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => navigate(1),
                            icon: const Icon(Icons.add),
                            label: const Text('Gerenciar plantas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _WateringCard extends StatelessWidget {
  const _WateringCard({required this.controller, required this.navigate});
  final GardenController controller;
  final ValueChanged<int> navigate;
  @override
  Widget build(BuildContext context) {
    final prefs = controller.selectedPlant!.irrigation;
    final automatic = prefs.mode == IrrigationMode.automatic;
    final event = controller.events.firstOrNull;
    return Surface(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Irrigação',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      controller.pump == PumpState.running
                          ? 'Simulando ciclo…'
                          : 'Modo ${automatic ? 'automático' : 'manual'}',
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Modo automático simulado',
                child: Switch(
                  value: automatic,
                  onChanged: controller.busy
                      ? null
                      : (value) => controller.updateIrrigation(
                          IrrigationPreferences(
                            minimum: prefs.minimum,
                            target: prefs.target,
                            mode: value
                                ? IrrigationMode.automatic
                                : IrrigationMode.manual,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          InkWell(
            onTap: () => navigate(4),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event == null
                          ? 'Nenhuma irrigação nesta sessão'
                          : 'Última irrigação: ${dateLabel(event.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => navigate(3),
              child: const Text('Controlar irrigação'),
            ),
          ),
        ],
      ),
    );
  }
}
