import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mygardenapp/app.dart';
import 'package:mygardenapp/data/preferences_store.dart';
import 'package:mygardenapp/data/simulated_garden_repository.dart';
import 'package:mygardenapp/screens/licenses_screen.dart';
import 'package:mygardenapp/state/garden_controller.dart';
import 'package:mygardenapp/theme/garden_theme.dart';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'menus selecionam e navegam com fonte ampliada em ${mode.name}',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        late GardenController controller;
        await tester.runAsync(() async {
          controller = GardenController(
            repository: SimulatedGardenRepository(latency: Duration.zero),
            preferencesStore: MemoryPreferencesStore(),
          );
          await controller.initialize();
          await controller.savePlant(
            name: 'Manjericão',
            species: '',
            notes: '',
          );
          await controller.setTheme(mode);
        });
        addTearDown(controller.dispose);
        await tester.pumpWidget(MyGardenApp(controller: controller));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('plant-selector')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final option = tester.getRect(
          find.widgetWithText(PopupMenuItem<String>, 'Hortelã'),
        );
        expect(option.width, lessThanOrEqualTo(280));
        expect(option.left, greaterThanOrEqualTo(20));
        expect(option.right, lessThanOrEqualTo(340));
        await tester.tap(find.text('Hortelã').last);
        await tester.pumpAndSettle();
        expect(controller.selectedPlant!.name, 'Hortelã');
        await tester.tap(find.byKey(const ValueKey('nav-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Opções de Hortelã'));
        await tester.pumpAndSettle();
        expect(find.text('Remover planta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Informações da planta'));
        await tester.pumpAndSettle();
        expect(find.text('Fechar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'licenças preservam todos os avisos e permitem voltar em ${mode.name}',
      (tester) async {
        LicenseRegistry.reset();
        addTearDown(LicenseRegistry.reset);
        LicenseRegistry.addLicense(
          () => Stream.fromIterable([
            LicenseEntryWithLineBreaks([
              'Biblioteca A',
              'Biblioteca B',
            ], 'Copyright original A.\n\nTermos completos do primeiro aviso.'),
            LicenseEntryWithLineBreaks([
              'Biblioteca A',
            ], 'Segundo aviso preservado.'),
          ]),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: GardenTheme.build(
              mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
            ),
            home: const LicensesScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Biblioteca B'), findsOneWidget);
        expect(find.text('2 licenças'), findsOneWidget);
        await tester.tap(find.text('Biblioteca A'));
        await tester.pumpAndSettle();
        expect(find.text('Copyright original A.'), findsOneWidget);
        expect(
          find.text('Termos completos do primeiro aviso.'),
          findsOneWidget,
        );
        expect(find.text('Segundo aviso preservado.'), findsOneWidget);
        expect(find.byType(SelectionArea), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Biblioteca B'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
