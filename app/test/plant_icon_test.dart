import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/domain/models.dart';
import 'package:mygardenapp/state/garden_controller.dart';
import 'package:mygardenapp/theme/garden_theme.dart';
import 'package:mygardenapp/widgets/plant_icon.dart';

void main() {
  test(
    'cadastros antigos ou ícones desconhecidos mantêm os dados da planta',
    () {
      final old = Plant(
        id: 'old',
        name: 'Minha planta',
        species: 'Espécie',
        notes: 'Notas',
        irrigation: IrrigationPreferences(),
      ).toJson()..remove('icon');
      expect(Plant.fromJson(old).icon, PlantIcon.mint);
      old['icon'] = 'unknown-future-icon';
      final restored = Plant.fromJson(old);
      expect(restored.name, 'Minha planta');
      expect(restored.notes, 'Notas');
      expect(restored.icon, PlantIcon.mint);
    },
  );

  test('ícone editado persiste e é preservado por outras alterações', () async {
    final store = MemoryPreferencesStore();
    GardenController create() => GardenController(
      preferencesStore: store,
      repository: SimulatedGardenRepository(latency: Duration.zero),
    );
    final c = create();
    addTearDown(c.dispose);
    await c.initialize();
    await c.savePlant(
      original: c.selectedPlant,
      name: 'Horta',
      species: '',
      notes: '',
      icon: PlantIcon.chives,
    );
    await c.savePlant(
      original: c.selectedPlant,
      name: 'Cebolinha da varanda',
      species: '',
      notes: 'Sol',
    );
    await c.updateIrrigation(IrrigationPreferences(minimum: 30, target: 60));
    final restored = create();
    addTearDown(restored.dispose);
    await restored.initialize();
    expect(restored.selectedPlant!.icon, PlantIcon.chives);
    expect(restored.selectedPlant!.name, 'Cebolinha da varanda');
    expect(restored.selectedPlant!.irrigation.minimum, 30);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'três ícones acessíveis em largura estreita e fonte ampliada $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        var selected = PlantIcon.mint;
        await tester.pumpWidget(
          MaterialApp(
            theme: GardenTheme.build(brightness),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(40),
                child: StatefulBuilder(
                  builder: (context, setState) => SingleChildScrollView(
                    child: PlantIconPicker(
                      value: selected,
                      onChanged: (icon) => setState(() => selected = icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final icon in PlantIcon.values) {
          final option = find.byKey(ValueKey('plant-icon-${icon.name}'));
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pumpAndSettle();
          expect(selected, icon);
          expect(tester.takeException(), isNull);
        }
        expect(find.byType(PlantIconImage), findsNWidgets(3));
      },
    );
  }
}
