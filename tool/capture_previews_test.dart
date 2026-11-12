// Optional offscreen visual review, separate from the regression suite.
// flutter test tool/capture_previews_test.dart
//   --dart-define=previewFontDirectory=<flutter>/bin/cache/artifacts/material_fonts
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/app.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/state/garden_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const fontDirectory = String.fromEnvironment('previewFontDirectory');
    if (fontDirectory.isEmpty) {
      throw ArgumentError(
        'Provide previewFontDirectory to render with Roboto.',
      );
    }
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      loader.addFont(
        File('$fontDirectory/roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File('$fontDirectory/materialicons-regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await icons.load();
  });

  testWidgets('render loading', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GardenController(
      repository: SimulatedGardenRepository(latency: Duration.zero),
      preferencesStore: MemoryPreferencesStore(),
    );
    addTearDown(controller.dispose);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MyGardenApp(controller: controller),
      ),
    );
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await controller.setTheme(mode);
      await tester.pump();
      await tester.runAsync(
        () => precacheImage(
          ResizeImage(
            AssetImage('assets/brand/icon-${mode.name}.png'),
            width: 180,
          ),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/screenshots/loading-${mode.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  for (final entry in <String, Size>{
    'mobile': const Size(393, 852),
    'tablet-portrait': const Size(800, 1100),
    'tablet-landscape': const Size(1024, 768),
    'desktop': const Size(1440, 960),
  }.entries) {
    testWidgets('render ${entry.key}', (tester) async {
      final originalShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GardenController(
          repository: SimulatedGardenRepository(latency: Duration.zero),
          preferencesStore: MemoryPreferencesStore(),
        );
        addTearDown(controller.dispose);
        await tester.runAsync(controller.initialize);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MyGardenApp(controller: controller),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const ResizeImage(
              AssetImage('assets/images/mint-cutout.png'),
              width: 320,
            ),
            boundaryKey.currentContext!,
          ),
        );
        await tester.pumpAndSettle();

        Future<void> capture(String suffix) async {
          expect(tester.takeException(), isNull);
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              'docs/screenshots/stage1b-${entry.key}-$suffix.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await controller.setTheme(mode);
          await tester.pumpAndSettle();
          await capture(mode.name);
        }
        if (entry.key == 'mobile') {
          for (final section in {
            1: 'garden',
            2: 'monitoring',
            5: 'settings',
          }.entries) {
            await tester.tap(find.byKey(ValueKey('nav-${section.key}')));
            await tester.pumpAndSettle();
            await capture(section.value);
          }
        }
      } finally {
        debugDisableShadows = originalShadows;
      }
    });
  }
}
