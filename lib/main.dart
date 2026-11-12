import 'package:flutter/material.dart';

import 'app.dart';
import 'data/preferences_store.dart';
import 'data/simulated_garden_repository.dart';
import 'state/garden_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MyGardenApp(
      controller: GardenController(
        repository: SimulatedGardenRepository(),
        preferencesStore: LocalPreferencesStore(),
      )..initialize(),
    ),
  );
}
