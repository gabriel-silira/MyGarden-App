import 'package:flutter/material.dart';

import 'app.dart';
import 'data/preferences_store.dart';
import 'data/simulated_garden_repository.dart';
import 'state/garden_controller.dart';
import 'platform/launcher_icon_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GardenController(
    repository: SimulatedGardenRepository(),
    preferencesStore: LocalPreferencesStore(),
  );
  runApp(
    LauncherIconSync(
      controller: controller,
      child: MyGardenApp(controller: controller),
    ),
  );
  controller.initialize();
}
