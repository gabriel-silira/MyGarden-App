import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/platform/launcher_icon_sync.dart';
import 'package:mygardenapp/state/garden_controller.dart';

void main() {
  const channel = MethodChannel('mygarden/launcher_icon');
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expectSync(call.method, 'setTheme');
          calls.add((call.arguments as Map)['theme'] as String);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  GardenController controller(PreferencesStore store) {
    final result = GardenController(
      repository: SimulatedGardenRepository(latency: Duration.zero),
      preferencesStore: store,
    );
    addTearDown(result.dispose);
    return result;
  }

  Future<void> mount(WidgetTester tester, GardenController garden) =>
      tester.pumpWidget(
        LauncherIconSync(controller: garden, child: const SizedBox()),
      );

  testWidgets('restaura o tema antes de sincronizar e acompanha as escolhas', (
    tester,
  ) async {
    final store = MemoryPreferencesStore();
    final previous = controller(store);
    await tester.runAsync(previous.initialize);
    await previous.setTheme(ThemeMode.dark);
    final garden = controller(store);
    await mount(tester, garden);
    expect(calls, isEmpty);
    final initialization = garden.initialize();
    await tester.pumpAndSettle();
    await initialization;
    expect(calls, ['dark']);

    for (final theme in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      await garden.setTheme(theme);
      await tester.pump();
    }
    expect(calls, ['dark', 'light', 'dark', 'system']);
    await garden.setGardenName('Meu jardim pessoal');
    await tester.pump();
    expect(calls.length, 4);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'falha nativa não interrompe o app e tenta novamente ao retornar',
    (tester) async {
      var attempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            attempts++;
            if (attempts == 1) {
              throw PlatformException(code: 'launcher_icon_failed');
            }
            return null;
          });
      final garden = controller(MemoryPreferencesStore());
      await tester.runAsync(garden.initialize);
      await mount(tester, garden);
      await tester.pump();
      expect(attempts, 1);
      expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('não chama a integração Android em outras plataformas', (
    tester,
  ) async {
    final garden = controller(MemoryPreferencesStore());
    await tester.runAsync(garden.initialize);
    await mount(tester, garden);
    await garden.setTheme(ThemeMode.light);
    await tester.pump();
    expect(calls, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
