import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../widgets/garden_widgets.dart';
import '../widgets/mint_symbol.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.onIrrigation,
  });
  final GardenController controller;
  final VoidCallback onIrrigation;
  Future<void> _open(
    BuildContext context,
    String title,
    Widget Function(BuildContext) builder,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: builder(context),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionTitle(
        'Configurações',
        subtitle: 'Personalize o aplicativo.',
      ),
      Surface(
        onTap: () => _open(
          context,
          'Meu jardim',
          (_) => _GardenName(controller: controller),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.gardenName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Seu espaço • salvo neste dispositivo'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Surface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            _SettingsItem(
              icon: Icons.eco_outlined,
              title: 'Automação e irrigação',
              subtitle: 'Modo, limites e controle simulado',
              onTap: onIrrigation,
            ),
            const Divider(height: 1),
            _SettingsItem(
              icon: Icons.sensors,
              title: 'Sensores e dispositivos',
              subtitle: 'Simulador local • ESP32 no futuro',
              onTap: () => _open(
                context,
                'Sensores e dispositivos',
                (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Notice('Nenhum dispositivo físico conectado.'),
                    const SizedBox(height: 20),
                    Surface(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sensor de temperatura'),
                        subtitle: const Text(
                          'Exibir temperatura simulada nas leituras.',
                        ),
                        value: controller.temperatureEnabled,
                        onChanged: controller.busy
                            ? null
                            : controller.setTemperature,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      controller.repository.connection ==
                              DeviceConnection.disconnected
                          ? 'Cenário de desconexão do simulador ativo.'
                          : 'Fonte atual: simulador local.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A integração com ESP32 será adicionada em uma próxima etapa. '
                      'O protocolo e a calibração serão definidos junto ao firmware.',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _SettingsItem(
              icon: Icons.palette_outlined,
              title: 'Aparência',
              subtitle: 'Tema claro, escuro ou do sistema',
              onTap: () => _open(
                context,
                'Aparência',
                (_) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha como seu jardim aparece. A preferência fica salva neste dispositivo.',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BrandIcon(dark: false, size: 88),
                        const SizedBox(width: 32),
                        const BrandIcon(dark: true, size: 88),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...ThemeMode.values.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Surface(
                          padding: EdgeInsets.zero,
                          onTap: () => controller.setTheme(mode),
                          child: ListTile(
                            leading: Icon(switch (mode) {
                              ThemeMode.system =>
                                Icons.brightness_auto_outlined,
                              ThemeMode.light => Icons.light_mode_outlined,
                              ThemeMode.dark => Icons.dark_mode_outlined,
                            }),
                            title: Text(switch (mode) {
                              ThemeMode.system => 'Sistema',
                              ThemeMode.light => 'Claro',
                              ThemeMode.dark => 'Escuro',
                            }),
                            subtitle: mode == ThemeMode.system
                                ? const Text(
                                    'Acompanhar a preferência do dispositivo',
                                  )
                                : null,
                            trailing: controller.themeMode == mode
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (controller.storageWarning != null)
                      Notice(controller.storageWarning!, error: true),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'Sobre o MyGarden',
              subtitle: 'Versão 0.1.0',
              onTap: () => _open(
                context,
                'Sobre o MyGarden',
                (_) => Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandWordmark(),
                      const SizedBox(height: 20),
                      const Text(
                        'Seu jardim, mais inteligente.\nVersão 0.1.0 • modo de simulação',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cadastros e preferências ficam neste dispositivo. Nenhum dado é enviado à nuvem. '
                        'Leituras e eventos são temporários e reiniciados ao abrir o aplicativo.',
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: 'MyGarden',
                          applicationVersion: '0.1.0',
                        ),
                        child: const Text('Licenças de software'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Feito para acompanhar cada pequeno cuidado.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 9),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 27),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}

class _GardenName extends StatefulWidget {
  const _GardenName({required this.controller});
  final GardenController controller;
  @override
  State<_GardenName> createState() => _GardenNameState();
}

class _GardenNameState extends State<_GardenName> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.controller.gardenName);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Surface(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nome do jardim'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o nome do jardim.'
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (!_form.currentState!.validate()) return;
              await widget.controller.setGardenName(_name.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.controller.storageWarning == null
                          ? 'Nome do jardim salvo.'
                          : 'Nome atualizado nesta sessão.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Salvar nome'),
          ),
          if (widget.controller.storageWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Notice(widget.controller.storageWarning!, error: true),
            ),
        ],
      ),
    ),
  );
}
