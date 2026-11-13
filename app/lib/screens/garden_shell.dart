import 'package:flutter/material.dart';

import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/mint_symbol.dart';
import '../widgets/garden_backdrop.dart';
import 'overview_screen.dart';
import 'plants_screen.dart';
import 'monitoring_screen.dart';
import 'irrigation_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class GardenShell extends StatefulWidget {
  const GardenShell({super.key, required this.controller});
  final GardenController controller;
  @override
  State<GardenShell> createState() => _GardenShellState();
}

class _GardenShellState extends State<GardenShell> {
  int _section = 0;
  int _returnSection = 0;
  final _scroll = ScrollController();
  static const _primarySections = [0, 1, 2, 5];
  static const _labels = ['Início', 'Jardim', 'Monitoramento', 'Configurações'];
  static const _icons = [
    Icons.home_outlined,
    Icons.yard_outlined,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.yard,
    Icons.bar_chart,
    Icons.settings,
  ];
  bool get _secondary => _section == 3 || _section == 4;
  int get _navigationIndex =>
      _primarySections.indexOf(_secondary ? _returnSection : _section);
  void _navigate(int value) {
    setState(() {
      if ((value == 3 || value == 4) && !_secondary) _returnSection = _section;
      _section = value;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final controller = widget.controller;
    // Tablets retain bottom navigation, including landscape layouts.
    final desktop = MediaQuery.sizeOf(context).width >= 1200;
    final page = switch (_section) {
      0 => OverviewScreen(controller: controller, navigate: _navigate),
      1 => PlantsScreen(controller: controller, onMonitor: () => _navigate(2)),
      2 => MonitoringScreen(
        controller: controller,
        onAdd: () => _navigate(1),
        navigate: _navigate,
      ),
      3 => IrrigationScreen(controller: controller, onAdd: () => _navigate(1)),
      4 => HistoryScreen(controller: controller, onAdd: () => _navigate(1)),
      _ => SettingsScreen(
        controller: controller,
        onIrrigation: () => _navigate(3),
      ),
    };
    return PopScope(
      canPop: _section == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigate(_secondary ? _returnSection : 0);
      },
      child: Scaffold(
        body: GardenBackdrop(
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (desktop)
                  SizedBox(
                    width: 230,
                    child: Material(
                      color: c.surface.withValues(alpha: .72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 24, 16, 26),
                            child: BrandWordmark(),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Column(
                                  children: List.generate(
                                    4,
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        key: ValueKey(
                                          'nav-${_primarySections[i]}',
                                        ),
                                        selected: _navigationIndex == i,
                                        selectedTileColor: c.primaryContainer,
                                        selectedColor: c.onPrimaryContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        leading: Icon(
                                          _navigationIndex == i
                                              ? _selectedIcons[i]
                                              : _icons[i],
                                        ),
                                        title: Text(
                                          _labels[i],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onTap: () =>
                                            _navigate(_primarySections[i]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Surface(
                              padding: const EdgeInsets.all(14),
                              onTap: () => _navigate(5),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, color: c.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.gardenName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        Text(
                                          'Preferências locais',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 68,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: desktop ? 30 : 20,
                          ),
                          child: Row(
                            children: [
                              if (_secondary)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    tooltip: 'Voltar',
                                    onPressed: () => _navigate(_returnSection),
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                ),
                              if (!desktop)
                                const Expanded(child: BrandWordmark())
                              else
                                Expanded(
                                  child: Text(
                                    'Seu jardim, mais inteligente.',
                                    style: TextStyle(color: c.onSurfaceVariant),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Sobre a simulação',
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                      'Um jardim para experimentar',
                                    ),
                                    content: const Text(
                                      'Todas as leituras e irrigações são simuladas. Nenhum controlador físico está conectado. '
                                      'Experimente diferentes condições em Monitoramento.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Entendi'),
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(Icons.science_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: !controller.initialized
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                controller: _scroll,
                                padding: EdgeInsets.fromLTRB(
                                  desktop ? 30 : 20,
                                  8,
                                  desktop ? 30 : 20,
                                  28,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1140,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.science_outlined,
                                                size: 14,
                                                color: c.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Simulação • nenhum hardware conectado',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (controller.busy)
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: LinearProgressIndicator(
                                              semanticsLabel: 'Operação simulada em andamento',
                                            ),
                                          ),
                                        if (controller.error != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 14,
                                            ),
                                            child: Notice(
                                              controller.error!,
                                              error: true,
                                            ),
                                          ),
                                        if (controller.storageWarning != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 14,
                                            ),
                                            child: Notice(
                                              controller.storageWarning!,
                                              error: true,
                                            ),
                                          ),
                                        AnimatedSwitcher(
                                          duration:
                                              MediaQuery.disableAnimationsOf(
                                                context,
                                              )
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 160,
                                                ),
                                          child: KeyedSubtree(
                                            key: ValueKey(_section),
                                            child: page,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: desktop
            ? null
            : ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: NavigationBar(
                  selectedIndex: _navigationIndex,
                  onDestinationSelected: (value) =>
                      _navigate(_primarySections[value]),
                  destinations: List.generate(
                    4,
                    (i) => NavigationDestination(
                      key: ValueKey('nav-${_primarySections[i]}'),
                      icon: Icon(_icons[i]),
                      selectedIcon: Icon(_selectedIcons[i]),
                      tooltip: _labels[i],
                      label: const [
                        'Início',
                        'Jardim',
                        'Monitorar',
                        'Config.',
                      ][i],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
