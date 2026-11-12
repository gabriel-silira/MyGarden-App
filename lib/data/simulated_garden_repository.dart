import '../domain/models.dart';
import 'garden_repository.dart';

class SimulatedGardenRepository implements GardenRepository, SimulationControl {
  SimulatedGardenRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 450),
    this.irrigationDuration = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final Duration latency;
  final Duration irrigationDuration;
  final Map<String, double> _moisture = {};
  final Map<String, int> _steps = {};
  bool _pumping = false;
  int _eventId = 0;
  SimulationScenario _scenario = SimulationScenario.balanced;
  @override
  DataSource get source => DataSource.simulated;
  @override
  SimulationScenario get scenario => _scenario;
  @override
  DeviceConnection get connection =>
      _scenario == SimulationScenario.disconnected
      ? DeviceConnection.disconnected
      : DeviceConnection.simulated;
  @override
  void setScenario(SimulationScenario value) {
    _scenario = value;
    _moisture.clear();
    _steps.clear();
  }

  double get _baseline => switch (_scenario) {
    SimulationScenario.dry => 24,
    SimulationScenario.wet => 88,
    _ => 58,
  };
  void _checkConnection() {
    if (connection == DeviceConnection.disconnected) {
      throw const GardenException(
        'simulated_offline',
        'Conexão interrompida no simulador. Escolha outro cenário para reconectar.',
      );
    }
  }

  @override
  Future<List<SensorReading>> history(Plant plant) async {
    final now = _clock();
    return List.generate(
      24,
      (i) => SensorReading(
        plantId: plant.id,
        deviceId: plant.deviceId ?? 'sim-${plant.id}',
        moisture: 58 + (i % 8) * .7,
        temperature: 23 + (i % 5) * .3,
        timestamp: now.subtract(Duration(hours: 23 - i)),
        source: source,
      ),
    );
  }

  @override
  Future<SensorReading?> read(
    Plant plant, {
    required bool temperatureEnabled,
  }) async {
    await Future<void>.delayed(latency);
    _checkConnection();
    if (_scenario == SimulationScenario.empty) return null;
    final step = _steps.update(plant.id, (v) => v + 1, ifAbsent: () => 0);
    const drift = [0.0, -0.8, -0.5, 0.3, -0.4];
    final value =
        ((_moisture[plant.id] ?? _baseline) + drift[step % drift.length])
            .clamp(0, 100)
            .toDouble();
    _moisture[plant.id] = value;
    return SensorReading(
      plantId: plant.id,
      deviceId: plant.deviceId ?? 'sim-${plant.id}',
      moisture: value,
      temperature: temperatureEnabled ? 24 + (step % 4) * .2 : null,
      timestamp: _clock(),
      source: source,
    );
  }

  @override
  Future<IrrigationEvent> irrigate(
    Plant plant, {
    required IrrigationMode mode,
  }) async {
    _checkConnection();
    if (_scenario == SimulationScenario.empty) {
      throw const GardenException(
        'no_reading',
        'Atualize uma leitura antes de irrigar.',
      );
    }
    if (_pumping) {
      throw const GardenException(
        'busy',
        'Uma simulação já está em andamento.',
      );
    }
    _pumping = true;
    try {
      await Future<void>.delayed(irrigationDuration);
      _checkConnection();
      _moisture[plant.id] = mode == IrrigationMode.automatic
          ? plant.irrigation.target
          : ((_moisture[plant.id] ?? _baseline) + 8).clamp(0, 100).toDouble();
      return IrrigationEvent(
        id: 'sim-${++_eventId}',
        plantId: plant.id,
        timestamp: _clock(),
        mode: mode,
        duration: irrigationDuration,
        source: source,
      );
    } finally {
      _pumping = false;
    }
  }

  @override
  void dispose() {}
}
