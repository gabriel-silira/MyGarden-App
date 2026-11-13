import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({
    super.key,
    required this.controller,
    required this.onAdd,
  });
  final GardenController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle(
        'Irrigação',
        subtitle: 'Você escolhe como cuidar. Nós ajudamos a acompanhar.',
      ),
      const Notice(
        'Modo de simulação. Nenhum comando é enviado a uma bomba física.',
      ),
      const SizedBox(height: 20),
      if (controller.selectedPlant == null)
        EmptyGarden(onAdd: onAdd)
      else ...[
        PlantSelector(controller: controller),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    controller.pump == PumpState.running
                        ? Icons.water_drop
                        : Icons.water_drop_outlined,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.pump == PumpState.running
                              ? 'Simulando irrigação…'
                              : 'Bomba simulada em repouso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text('Controlador físico não conectado'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IrrigationControls(controller: controller),
              const SizedBox(height: 24),
              if (controller.selectedPlant!.irrigation.mode ==
                  IrrigationMode.manual)
                FilledButton.icon(
                  onPressed: controller.canIrrigate
                      ? () async {
                          final ok = await controller.irrigate();
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Irrigação simulada concluída. Nenhum hardware foi acionado.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.water_drop_outlined),
                  label: Text(
                    controller.pump == PumpState.running
                        ? 'Simulando…'
                        : 'Simular irrigação',
                  ),
                )
              else ...[
                const Text(
                  'Ao atualizar, uma leitura abaixo do limite inicia um ciclo simulado até o alvo. '
                  'Não há automação em segundo plano.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.busy ? null : controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar e avaliar'),
                ),
              ],
              if (!controller.canIrrigate && !controller.busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'É necessária uma leitura disponível e conexão com o simulador. Verifique Monitoramento.',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Últimas irrigações',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        EventList(events: controller.events.take(8).toList()),
      ],
    ],
  );
}

class IrrigationControls extends StatefulWidget {
  const IrrigationControls({super.key, required this.controller});
  final GardenController controller;
  @override
  State<IrrigationControls> createState() => _IrrigationControlsState();
}

class _IrrigationControlsState extends State<IrrigationControls> {
  RangeValues? _draft;
  @override
  void didUpdateWidget(covariant IrrigationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent keys this editor by selected plant; committed values come from state.
    if (!widget.controller.busy) _draft = null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final p = controller.selectedPlant!.irrigation;
    final range = _draft ?? RangeValues(p.minimum, p.target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de irrigação',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: IrrigationMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(
                    mode == IrrigationMode.manual ? 'Manual' : 'Automático',
                  ),
                  selected: p.mode == mode,
                  onSelected: controller.busy
                      ? null
                      : (_) => controller.updateIrrigation(
                          IrrigationPreferences(
                            minimum: p.minimum,
                            target: p.target,
                            mode: mode,
                          ),
                        ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Limite ${range.start.round()}%  →  Alvo ${range.end.round()}%',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RangeSlider(
          values: range,
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '${range.start.round()}%',
            '${range.end.round()}%',
          ),
          semanticFormatterCallback: (value) => '${value.round()} por cento',
          onChanged: controller.busy
              ? null
              : (value) {
                  if (value.end - value.start >= 5) {
                    setState(() => _draft = value);
                  }
                },
          onChangeEnd: controller.busy
              ? null
              : (_) {
                  final value = _draft;
                  if (value != null) {
                    controller.updateIrrigation(
                      IrrigationPreferences(
                        minimum: value.start,
                        target: value.end,
                        mode: p.mode,
                      ),
                    );
                  }
                },
        ),
        const Text(
          'Faixa de referência para demonstração. Não representa uma recomendação agronômica.',
        ),
      ],
    );
  }
}
