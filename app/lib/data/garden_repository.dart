import '../domain/models.dart';

/// Transport-neutral contract. Only the simulator is wired into this app.
abstract interface class GardenRepository {
  DataSource get source;
  DeviceConnection get connection;
  Future<List<SensorReading>> history(Plant plant);
  Future<SensorReading?> read(Plant plant, {required bool temperatureEnabled});
  Future<IrrigationEvent> irrigate(Plant plant, {required IrrigationMode mode});
  void dispose();
}

/// Simulation controls deliberately kept outside the hardware contract.
abstract interface class SimulationControl {
  SimulationScenario get scenario;
  void setScenario(SimulationScenario value);
}
