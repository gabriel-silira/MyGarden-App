import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mygardenapp/app.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/domain/models.dart';
import 'package:mygardenapp/state/garden_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Run twice, in separate app processes, with validationPhase=write then read.
// This key is separate from the user's production preferences.
const validationKey = 'mygarden.validation.stage2.v1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const capturePreviews = bool.fromEnvironment('capturePreviews');
  const phase = String.fromEnvironment(
    'validationPhase',
    defaultValue: 'write',
  );

  testWidgets('Android: interface e armazenamento real ($phase)', (
    tester,
  ) async {
    expect(['write', 'read'], contains(phase));
    final preferences = SharedPreferencesAsync();
    if (phase == 'write') await preferences.remove(validationKey);
    final controller = GardenController(
      repository: SimulatedGardenRepository(),
      preferencesStore: LocalPreferencesStore(storageKey: validationKey),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.storageWarning, isNull);
    final previewKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: MyGardenApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapText(String label) async {
      final target = find.text(label).last;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> navigate(int section) async {
      await tester.tap(find.byKey(ValueKey('nav-$section')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    if (phase == 'read') {
      // These values were written by the previous process, not by this test run.
      expect(controller.gardenName, 'Validação Android');
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.temperatureEnabled, isFalse);
      expect(controller.plants.map((p) => p.name), contains('Planta de teste'));
      expect(find.textContaining('Validação Android'), findsOneWidget);
      expect(
        controller.events,
        isEmpty,
      ); // Events intentionally belong to a session.
      Future<void> capture(String name) async {
        final boundary =
            previewKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(
          pixelRatio: tester.view.devicePixelRatio,
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data!.buffer.asUint8List();
        image.dispose();
        // Machine-readable evidence captured by the host test log.
        // ignore: avoid_print
        print('MYGARDEN_SCREENSHOT:$name:${base64Encode(bytes)}');
      }

      Future<void> orient(DeviceOrientation orientation, bool landscape) async {
        await SystemChrome.setPreferredOrientations([orientation]);
        for (var attempt = 0; attempt < 30; attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
          final size = tester.view.physicalSize;
          if ((size.width > size.height) == landscape) break;
        }
        await tester.pumpAndSettle();
        final size = tester.view.physicalSize;
        expect(size.width > size.height, landscape);
        expect(tester.takeException(), isNull);
      }

      try {
        await orient(DeviceOrientation.portraitUp, false);
        if (capturePreviews) {
          await tester.pumpAndSettle();
          await capture('stage2-android-portrait');
        }
        await orient(DeviceOrientation.landscapeLeft, true);
        expect(find.byType(NavigationDestination), findsNWidgets(4));
        if (capturePreviews) {
          await capture('stage2-android-landscape');
        }
        await orient(DeviceOrientation.portraitUp, false);
      } finally {
        await SystemChrome.setPreferredOrientations([]);
      }
      await navigate(1);
      expect(find.text('Planta de teste'), findsOneWidget);
      await preferences.remove(validationKey);
      return;
    }

    expect(find.text('Hortelã'), findsWidgets);
    await tapText('Controlar irrigação');
    await tapText('Simular irrigação');
    expect(controller.events, hasLength(1));
    expect(controller.events.single.source, DataSource.simulated);
    expect(controller.pump, PumpState.idle);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    await navigate(1);
    await tester.tap(find.byTooltip('Adicionar planta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Planta de teste');
    await tapText('Salvar planta');
    expect(controller.plants, hasLength(2));
    await navigate(2);
    await tapText('Histórico completo');
    expect(find.text('Histórico'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    await navigate(5);
    await tapText('Meu jardim');
    await tester.enterText(find.byType(TextFormField), 'Validação Android');
    await tapText('Salvar nome');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tapText('Aparência');
    await tapText('Escuro');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tapText('Sensores e dispositivos');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.temperatureEnabled, isFalse);
    expect(controller.storageWarning, isNull);
    expect(
      await LocalPreferencesStore(storageKey: validationKey).read(),
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
