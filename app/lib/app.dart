import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/garden_controller.dart';
import 'theme/garden_theme.dart';
import 'screens/garden_shell.dart';
import 'screens/loading_screen.dart';

class MyGardenApp extends StatelessWidget {
  const MyGardenApp({super.key, required this.controller});
  final GardenController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'MyGarden',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: GardenTheme.build(Brightness.light),
      darkTheme: GardenTheme.build(Brightness.dark),
      themeMode: controller.themeMode,
      home: controller.initialized
          ? GardenShell(controller: controller)
          : const LoadingScreen(),
    ),
  );
}
