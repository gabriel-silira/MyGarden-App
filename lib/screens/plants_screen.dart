import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/plant_tile.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({
    super.key,
    required this.controller,
    required this.onMonitor,
  });
  final GardenController controller;
  final VoidCallback onMonitor;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionTitle(
        'Meu jardim',
        subtitle: 'Plantas em acompanhamento (${controller.plants.length})',
        action: IconButton.filled(
          tooltip: 'Adicionar planta',
          onPressed: controller.busy
              ? null
              : () => editPlant(context, controller),
          icon: const Icon(Icons.add),
        ),
      ),
      if (controller.plants.isEmpty)
        EmptyGarden(onAdd: () => editPlant(context, controller)),
      ...controller.plants.map(
        (plant) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PlantTile(
            plant: plant,
            reading: controller.readingFor(plant.id),
            onTap: controller.busy
                ? null
                : () {
                    controller.selectPlant(plant.id);
                    onMonitor();
                  },
            trailing: PopupMenuButton<String>(
              tooltip: 'Opções de ${plant.name}',
              enabled: !controller.busy,
              onSelected: (value) async {
                if (value == 'monitor') {
                  controller.selectPlant(plant.id);
                  onMonitor();
                }
                if (value == 'edit') {
                  await editPlant(context, controller, plant);
                }
                if (value == 'details' && context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(plant.name),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.species.isEmpty
                                  ? 'Espécie não informada'
                                  : plant.species,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              plant.notes.isEmpty
                                  ? 'Nenhuma anotação.'
                                  : plant.notes,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Fonte: simulador • ${plant.deviceId ?? 'sem dispositivo físico associado'}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Limite ${plant.irrigation.minimum.round()}% • alvo ${plant.irrigation.target.round()}%',
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                }
                if (value == 'delete' && context.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Remover ${plant.name}?'),
                      content: const Text(
                        'O cadastro e o histórico desta planta nesta sessão serão removidos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remover'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await controller.removePlant(plant.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'monitor',
                  child: Text('Acompanhar planta'),
                ),
                PopupMenuItem(
                  value: 'details',
                  child: Text('Informações da planta'),
                ),
                PopupMenuItem(value: 'edit', child: Text('Editar planta')),
                PopupMenuItem(value: 'delete', child: Text('Remover planta')),
              ],
            ),
          ),
        ),
      ),
      if (controller.plants.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Toque em uma planta para acompanhar suas leituras. Os estados indicam a faixa de umidade simulada.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

Future<void> editPlant(
  BuildContext context,
  GardenController controller, [
  Plant? plant,
]) => showDialog<void>(
  context: context,
  builder: (_) => _PlantEditor(controller: controller, plant: plant),
);

class _PlantEditor extends StatefulWidget {
  const _PlantEditor({required this.controller, this.plant});
  final GardenController controller;
  final Plant? plant;
  @override
  State<_PlantEditor> createState() => _PlantEditorState();
}

class _PlantEditorState extends State<_PlantEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plant?.name);
  late final _species = TextEditingController(text: widget.plant?.species);
  late final _notes = TextEditingController(text: widget.plant?.notes);
  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.plant == null ? 'Nova planta' : 'Editar planta'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome da planta'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um nome.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _species,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Espécie (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Suas anotações (opcional)',
                ),
              ),
              const Text('O monitoramento deste cadastro será simulado.'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          widget.controller.savePlant(
            original: widget.plant,
            name: _name.text,
            species: _species.text,
            notes: _notes.text,
          );
          Navigator.pop(context);
        },
        child: const Text('Salvar planta'),
      ),
    ],
  );
}
