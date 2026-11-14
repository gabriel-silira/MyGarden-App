import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/domain/models.dart';
import 'package:mygardenapp/state/garden_controller.dart';

GardenController makeController({PreferencesStore? store}) => GardenController(
  repository: SimulatedGardenRepository(
    latency: Duration.zero,
    irrigationDuration: Duration.zero,
  ),
  preferencesStore: store ?? MemoryPreferencesStore(),
);

void main() {
  test('leituras limitam umidade e rejeitam dados não finitos', () {
    SensorReading reading(double moisture) => SensorReading(
      plantId: 'p',
      deviceId: 'sim',
      moisture: moisture,
      timestamp: DateTime(2026),
      source: DataSource.simulated,
    );
    expect(reading(-20).moisture, 0);
    expect(reading(140).moisture, 100);
    expect(() => reading(double.nan), throwsArgumentError);
    expect(() => reading(double.infinity), throwsArgumentError);
    expect(
      () => IrrigationPreferences(minimum: 70, target: 40),
      throwsArgumentError,
    );
    expect(
      () => IrrigationPreferences(minimum: 40, target: 40),
      throwsArgumentError,
    );
    expect(reading(20).condition(IrrigationPreferences()), SoilCondition.dry);
    expect(
      reading(50).condition(IrrigationPreferences()),
      SoilCondition.balanced,
    );
    expect(reading(80).condition(IrrigationPreferences()), SoilCondition.wet);
  });

  test(
    'cenários, ausência de dados, falha e recuperação são reativos',
    () async {
      final c = makeController();
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.latest!.moisture, 58);
      expect(c.readings.last, same(c.latest));
      await c.setScenario(SimulationScenario.dry);
      expect(c.latest!.moisture, lessThan(35));
      await c.setScenario(SimulationScenario.empty);
      expect(c.latest, isNull);
      expect(c.canIrrigate, isFalse);
      await c.setScenario(SimulationScenario.disconnected);
      expect(c.error, contains('Conexão interrompida'));
      expect(c.canIrrigate, isFalse);
      await c.setScenario(SimulationScenario.balanced);
      expect(c.error, isNull);
      expect(c.latest!.moisture, 58);
    },
  );

  test('irrigação manual registra somente simulação e respeita 100%', () async {
    final c = makeController();
    addTearDown(c.dispose);
    await c.initialize();
    await c.setScenario(SimulationScenario.wet);
    for (var i = 0; i < 8; i++) {
      expect(await c.irrigate(), isTrue);
    }
    expect(c.latest!.moisture, lessThanOrEqualTo(100));
    expect(c.events.length, 8);
    expect(
      c.events.every((event) => event.source == DataSource.simulated),
      isTrue,
    );
    expect(c.pump, PumpState.idle);
  });

  test(
    'automático usa limite e alvo e não dispara novamente dentro da faixa',
    () async {
      final c = makeController();
      addTearDown(c.dispose);
      await c.initialize();
      await c.updateIrrigation(
        IrrigationPreferences(
          minimum: 30,
          target: 70,
          mode: IrrigationMode.automatic,
        ),
      );
      await c.setScenario(SimulationScenario.dry);
      expect(c.events.single.mode, IrrigationMode.automatic);
      expect(c.latest!.moisture, closeTo(70, 1));
      await c.refresh();
      expect(c.events.length, 1);
      expect(await c.irrigate(), isFalse);
      expect(c.pump, PumpState.idle);
    },
  );

  test('operações concorrentes não duplicam evento', () async {
    final c = GardenController(
      repository: SimulatedGardenRepository(
        latency: Duration.zero,
        irrigationDuration: const Duration(milliseconds: 20),
      ),
      preferencesStore: MemoryPreferencesStore(),
    );
    addTearDown(c.dispose);
    await c.initialize();
    final first = c.irrigate();
    expect(c.pump, PumpState.running);
    expect(await c.irrigate(), isFalse);
    await first;
    expect(c.events.length, 1);
  });

  test(
    'preferências e plantas persistem, leituras permanecem isoladas',
    () async {
      final store = MemoryPreferencesStore();
      final c = makeController(store: store);
      addTearDown(c.dispose);
      await c.initialize();
      await c.setTheme(ThemeMode.dark);
      await c.setGardenName('Varanda');
      await c.setTemperature(false);
      await c.savePlant(
        name: 'Manjericão',
        species: 'Ocimum',
        notes: 'Cozinha',
        icon: PlantIcon.lemonBalm,
      );
      final basil = c.selectedPlant!;
      await c.irrigate();
      expect(c.events.length, 1);
      c.selectPlant('mint');
      expect(c.events, isEmpty);
      final restored = makeController(store: store);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.gardenName, 'Varanda');
      expect(restored.temperatureEnabled, false);
      expect(restored.latest!.temperature, isNull);
      expect(restored.plants.length, 2);
      expect(restored.plants.last.icon, PlantIcon.lemonBalm);
      expect(restored.events, isEmpty);
      await restored.removePlant(basil.id);
      await restored.removePlant('mint');
      expect(restored.selectedPlant, isNull);
      expect(restored.latest, isNull);
      final empty = makeController(store: store);
      addTearDown(empty.dispose);
      await empty.initialize();
      expect(empty.plants, isEmpty);
    },
  );

  test('dados locais corrompidos não impedem a inicialização', () async {
    final store = MemoryPreferencesStore()..value = '{bad data';
    final c = makeController(store: store);
    addTearDown(c.dispose);
    await c.initialize();
    expect(c.initialized, isTrue);
    expect(c.storageWarning, isNotNull);
    expect(c.plants.single.name, 'Hortelã');
  });

  test('falha ao salvar mantém app utilizável e mostra aviso', () async {
    final c = makeController(store: _FailingStore());
    addTearDown(c.dispose);
    await c.initialize();
    await c.setTheme(ThemeMode.dark);
    expect(c.themeMode, ThemeMode.dark);
    expect(c.storageWarning, contains('não puderam ser salvas'));
    await c.refresh();
    expect(c.latest, isNotNull);
  });
}

class _FailingStore implements PreferencesStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async => throw Exception('Disk unavailable');
}
