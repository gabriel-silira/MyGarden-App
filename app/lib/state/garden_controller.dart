import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/garden_repository.dart';
import '../data/preferences_store.dart';
import '../domain/models.dart';

class GardenController extends ChangeNotifier {
  GardenController({required this.repository, required this.preferencesStore});
  final GardenRepository repository;
  final PreferencesStore preferencesStore;
  final List<Plant> _plants = [
    Plant(
      id: 'mint',
      name: 'Hortelã',
      species: 'Mentha sp.',
      notes:
          'Uma companhia aromática para o seu jardim. '
          'Cadastro demonstrativo: adapte os cuidados à sua planta.',
      deviceId: 'sim-mint',
      irrigation: IrrigationPreferences(),
    ),
  ];
  final Map<String, List<SensorReading>> _history = {};
  final Map<String, SensorReading?> _latest = {};
  final List<IrrigationEvent> _events = [];
  String? selectedId = 'mint';
  String gardenName = 'Meu jardim';
  ThemeMode themeMode = ThemeMode.system;
  bool temperatureEnabled = true;
  bool busy = false;
  bool initialized = false;
  bool _disposed = false;
  PumpState pump = PumpState.idle;
  String? error;
  String? storageWarning;
  Future<void> _saveQueue = Future.value();
  List<Plant> get plants => List.unmodifiable(_plants);
  Plant? get selectedPlant =>
      _plants.where((p) => p.id == selectedId).firstOrNull;
  SensorReading? get latest => _latest[selectedId];
  SensorReading? readingFor(String plantId) => _latest[plantId];
  List<SensorReading> get readings =>
      List.unmodifiable(_history[selectedId] ?? []);
  List<IrrigationEvent> get events =>
      List.unmodifiable(_events.where((e) => e.plantId == selectedId));
  SimulationScenario get scenario => repository is SimulationControl
      ? (repository as SimulationControl).scenario
      : SimulationScenario.balanced;
  bool get canIrrigate =>
      !busy &&
      latest != null &&
      error == null &&
      repository.source == DataSource.simulated &&
      repository.connection == DeviceConnection.simulated;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    busy = true;
    _emit();
    try {
      final raw = await preferencesStore.read();
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final restored = (data['plants'] as List)
            .map((p) => Plant.fromJson(p as Map<String, dynamic>))
            .toList();
        final theme = ThemeMode.values.byName(data['theme'] as String);
        final name = data['gardenName'] as String;
        final temperature = data['temperature'] as bool;
        if (name.trim().isEmpty ||
            restored.any((p) => p.name.trim().isEmpty) ||
            restored.map((p) => p.id).toSet().length != restored.length) {
          throw const FormatException('Preferências inválidas');
        }
        _plants
          ..clear()
          ..addAll(restored);
        themeMode = theme;
        gardenName = name;
        temperatureEnabled = temperature;
        selectedId = _plants.firstOrNull?.id;
      }
    } catch (_) {
      storageWarning = 'Não foi possível recuperar as preferências. Usando os padrões desta sessão.';
    }
    try {
      for (final plant in _plants) {
        _history[plant.id] = await repository.history(plant);
        _record(
          await repository.read(plant, temperatureEnabled: temperatureEnabled),
          plant.id,
        );
      }
    } catch (e) {
      error = _message(e);
    }
    initialized = true;
    busy = false;
    _emit();
  }

  String _message(Object error) => error is GardenException
      ? error.message
      : 'Não foi possível concluir a operação. Tente atualizar novamente.';
  Future<void> _save() {
    final value = jsonEncode({
      'version': 1,
      'theme': themeMode.name,
      'gardenName': gardenName,
      'temperature': temperatureEnabled,
      'plants': _plants.map((p) => p.toJson()).toList(),
    });
    _saveQueue = _saveQueue.then((_) async {
      try {
        await preferencesStore.write(value);
        storageWarning = null;
      } catch (_) {
        storageWarning = 'As alterações valem nesta sessão, mas não puderam ser salvas no dispositivo.';
      }
      _emit();
    });
    return _saveQueue;
  }

  void selectPlant(String id) {
    if (busy || !_plants.any((p) => p.id == id)) return;
    selectedId = id;
    error = null;
    _emit();
  }

  void _record(SensorReading? reading, String plantId) {
    _latest[plantId] = reading;
    if (reading != null) {
      final history = _history.putIfAbsent(plantId, () => []);
      history.add(reading);
      if (history.length > 500) history.removeRange(0, history.length - 500);
    }
  }

  Future<void> refresh() async {
    final plant = selectedPlant;
    if (busy || plant == null) return;
    busy = true;
    error = null;
    _emit();
    try {
      final reading = await repository.read(
        plant,
        temperatureEnabled: temperatureEnabled,
      );
      _record(reading, plant.id);
      if (reading != null &&
          repository.source == DataSource.simulated &&
          plant.irrigation.mode == IrrigationMode.automatic &&
          reading.moisture < plant.irrigation.minimum) {
        await _irrigate(plant, IrrigationMode.automatic);
      }
    } catch (e) {
      error = _message(e);
    } finally {
      busy = false;
      pump = PumpState.idle;
      _emit();
    }
  }

  Future<void> _irrigate(Plant plant, IrrigationMode mode) async {
    pump = PumpState.running;
    _emit();
    final event = await repository.irrigate(plant, mode: mode);
    _events.insert(0, event);
    if (_events.length > 200) _events.removeLast();
    _record(
      await repository.read(plant, temperatureEnabled: temperatureEnabled),
      plant.id,
    );
  }

  Future<bool> irrigate() async {
    if (!canIrrigate ||
        selectedPlant!.irrigation.mode != IrrigationMode.manual) {
      return false;
    }
    busy = true;
    error = null;
    _emit();
    var success = false;
    try {
      await _irrigate(selectedPlant!, IrrigationMode.manual);
      success = true;
    } catch (e) {
      error = _message(e);
    } finally {
      busy = false;
      pump = PumpState.idle;
      _emit();
    }
    return success;
  }

  Future<void> setScenario(SimulationScenario value) async {
    if (busy || repository is! SimulationControl) return;
    (repository as SimulationControl).setScenario(value);
    _latest.clear();
    error = null;
    await refresh();
    _emit();
  }

  Future<void> setTheme(ThemeMode value) async {
    themeMode = value;
    _emit();
    await _save();
  }

  Future<void> setGardenName(String value) async {
    if (value.trim().isEmpty) return;
    gardenName = value.trim();
    _emit();
    await _save();
  }

  Future<void> setTemperature(bool value) async {
    if (busy) return;
    temperatureEnabled = value;
    _emit();
    await _save();
    await refresh();
  }

  Future<void> updateIrrigation(IrrigationPreferences preferences) async {
    final plant = selectedPlant;
    if (plant == null || busy) return;
    _plants[_plants.indexOf(plant)] = plant.copyWith(irrigation: preferences);
    _emit();
    await _save();
  }

  Future<void> savePlant({
    Plant? original,
    required String name,
    required String species,
    required String notes,
  }) async {
    if (busy || name.trim().isEmpty) return;
    if (original != null) {
      final index = _plants.indexWhere((p) => p.id == original.id);
      if (index < 0) return;
      _plants[index] = original.copyWith(
        name: name.trim(),
        species: species.trim(),
        notes: notes.trim(),
      );
    } else {
      final id = 'plant-${DateTime.now().microsecondsSinceEpoch}';
      _plants.add(
        Plant(
          id: id,
          name: name.trim(),
          species: species.trim(),
          notes: notes.trim(),
          irrigation: IrrigationPreferences(),
        ),
      );
      selectedId = id;
    }
    _emit();
    await _save();
    await refresh();
  }

  Future<void> removePlant(String id) async {
    if (busy) return;
    _plants.removeWhere((p) => p.id == id);
    _history.remove(id);
    _latest.remove(id);
    _events.removeWhere((e) => e.plantId == id);
    if (selectedId == id) selectedId = _plants.firstOrNull?.id;
    error = null;
    _emit();
    await _save();
  }

  @override
  void dispose() {
    _disposed = true;
    repository.dispose();
    super.dispose();
  }
}
