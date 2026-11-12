import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/app.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/domain/models.dart';
import 'package:mygardenapp/state/garden_controller.dart';
import 'package:mygardenapp/screens/loading_screen.dart';
import 'package:mygardenapp/widgets/mint_symbol.dart';

Future<GardenController> launch(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = GardenController(
    repository: SimulatedGardenRepository(
      latency: Duration.zero,
      irrigationDuration: Duration.zero,
    ),
    preferencesStore: MemoryPreferencesStore(),
  );
  await tester.runAsync(c.initialize);
  addTearDown(c.dispose);
  await tester.pumpWidget(MyGardenApp(controller: c));
  await tester.pumpAndSettle();
  return c;
}

Future<void> navigate(WidgetTester tester, int section) async {
  await tester.tap(find.byKey(ValueKey('nav-$section')));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class PendingPreferencesStore implements PreferencesStore {
  final result = Completer<String?>();
  @override
  Future<String?> read() => result.future;
  @override
  Future<void> write(String value) async {}
}

void main() {
  for (final readFails in [false, true]) {
    testWidgets('carregamento termina com falha de leitura: $readFails', (
      tester,
    ) async {
      final store = PendingPreferencesStore();
      final controller = GardenController(
        repository: SimulatedGardenRepository(latency: Duration.zero),
        preferencesStore: store,
      );
      addTearDown(controller.dispose);
      final initialization = controller.initialize();
      await tester.pumpWidget(MyGardenApp(controller: controller));
      expect(find.byType(LoadingScreen), findsOneWidget);
      expect(find.text('Preparando seu jardim…'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNothing);
      if (readFails) {
        store.result.completeError(StateError('armazenamento indisponível'));
      } else {
        store.result.complete(null);
      }
      await tester.pumpAndSettle();
      await initialization;
      expect(find.byType(LoadingScreen), findsNothing);
      expect(find.text('Olá!'), findsOneWidget);
      expect(controller.storageWarning, readFails ? isNotNull : isNull);
      expect(tester.takeException(), isNull);
    });
  }
  for (final size in [
    const Size(320, 740),
    const Size(393, 852),
    const Size(800, 1100),
    const Size(1024, 768),
    const Size(1440, 960),
  ]) {
    testWidgets('quatro destinos e seis áreas sem overflow em $size', (
      tester,
    ) async {
      final c = await launch(tester, size);
      expect(find.byType(BrandWordmark), findsOneWidget);
      expect(find.text('Hortelã'), findsWidgets);
      expect(
        find.byType(NavigationDestination),
        size.width < 1200 ? findsNWidgets(4) : findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Controlar irrigação');
      expect(find.text('Simular irrigação'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Olá!'), findsOneWidget);
      await navigate(tester, 1);
      expect(find.text('Meu jardim'), findsWidgets);
      expect(tester.takeException(), isNull);
      await navigate(tester, 2);
      expect(find.text('Monitoramento'), findsWidgets);
      await tapText(tester, 'Histórico completo');
      expect(find.text('Histórico'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Histórico completo'), findsOneWidget);
      await navigate(tester, 5);
      await tapText(tester, 'Aparência');
      await tapText(tester, 'Escuro');
      expect(c.themeMode, ThemeMode.dark);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      for (final section in [0, 1, 2, 5]) {
        await navigate(tester, section);
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('fonte ampliada, cenários indisponíveis e jardim vazio', (
    tester,
  ) async {
    final c = await launch(tester, const Size(393, 852), textScale: 1.8);
    expect(tester.takeException(), isNull);
    for (final section in [1, 2, 5]) {
      await navigate(tester, section);
      expect(tester.takeException(), isNull);
    }
    await navigate(tester, 2);
    await tester.runAsync(() => c.setScenario(SimulationScenario.disconnected));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conexão interrompida'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => c.setScenario(SimulationScenario.empty));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem leitura atual'), findsOneWidget);
    await c.removePlant('mint');
    await tester.pumpAndSettle();
    expect(find.text('Seu jardim começa aqui'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('cadastro mantém validação e edição acessível', (tester) async {
    final c = await launch(tester, const Size(393, 852));
    await navigate(tester, 1);
    await tester.tap(find.byTooltip('Adicionar planta'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Salvar planta');
    expect(find.text('Informe um nome.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Alecrim');
    await tapText(tester, 'Salvar planta');
    expect(c.plants.length, 2);
    expect(c.selectedPlant!.name, 'Alecrim');
    await tester.ensureVisible(find.byTooltip('Opções de Alecrim'));
    await tester.tap(find.byTooltip('Opções de Alecrim'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Editar planta');
    await tester.enterText(
      find.byType(TextFormField).first,
      'Alecrim da varanda',
    );
    await tapText(tester, 'Salvar planta');
    expect(c.selectedPlant!.name, 'Alecrim da varanda');
    expect(tester.takeException(), isNull);
  });
  testWidgets('irrigação continua acessível e registra evento', (tester) async {
    final c = await launch(tester, const Size(393, 852));
    await tapText(tester, 'Controlar irrigação');
    await tapText(tester, 'Simular irrigação');
    expect(c.events.length, 1);
    expect(
      find.text('Irrigação simulada concluída. Nenhum hardware foi acionado.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('atalho automático usa as preferências existentes', (
    tester,
  ) async {
    final c = await launch(tester, const Size(393, 852));
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(c.selectedPlant!.irrigation.mode, IrrigationMode.automatic);
    await tester.runAsync(() => c.setScenario(SimulationScenario.dry));
    await tester.pumpAndSettle();
    expect(c.events.single.mode, IrrigationMode.automatic);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nome e sensor permanecem editáveis nas configurações', (
    tester,
  ) async {
    final c = await launch(tester, const Size(393, 852));
    await navigate(tester, 5);
    await tapText(tester, 'Meu jardim');
    await tester.enterText(find.byType(TextFormField), 'Varanda');
    await tapText(tester, 'Salvar nome');
    expect(c.gardenName, 'Varanda');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Sensores e dispositivos');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(c.temperatureEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
