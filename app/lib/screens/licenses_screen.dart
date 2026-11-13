import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/garden_backdrop.dart';
import '../widgets/mint_symbol.dart';

/// Presents the original Flutter registry notices without rewriting their text.
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late Future<Map<String, List<LicenseEntry>>> _licenses = _load();

  Future<Map<String, List<LicenseEntry>>> _load() async {
    final packages = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        packages.putIfAbsent(package, () => []).add(entry);
      }
    }
    return packages;
  }

  @override
  Widget build(BuildContext context) => _LicenseLayout(
    title: 'Licenças de software',
    child: FutureBuilder<Map<String, List<LicenseEntry>>>(
      future: _licenses,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar as licenças.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _licenses = _load()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregando licenças',
            ),
          );
        }
        final packages = snapshot.data!;
        final names = packages.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: names.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: 24)
              : const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandWordmark(),
                  const SizedBox(height: 16),
                  Text(
                    'Bibliotecas que fazem parte do MyGarden.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    names.isEmpty
                        ? 'Nenhuma licença disponível nesta execução.'
                        : 'Selecione uma biblioteca para ler seus avisos e licenças.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }
            final name = names[index - 1];
            return Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${packages[name]!.length} ${packages[name]!.length == 1 ? 'licença' : 'licenças'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _LicenseDetails(
                      package: name,
                      licenses: packages[name]!,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _LicenseDetails extends StatelessWidget {
  const _LicenseDetails({required this.package, required this.licenses});
  final String package;
  final List<LicenseEntry> licenses;

  @override
  Widget build(BuildContext context) => _LicenseLayout(
    title: 'Licenças da biblioteca',
    child: SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(package, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          for (var index = 0; index < licenses.length; index++) ...[
            if (index > 0) const Divider(height: 40),
            for (final paragraph in licenses[index].paragraphs)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12,
                  left: paragraph.indent < 0 ? 0 : paragraph.indent * 16.0,
                ),
                child: Text(
                  paragraph.text,
                  textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                      ? TextAlign.center
                      : TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(height: 1.6),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class _LicenseLayout extends StatelessWidget {
  const _LicenseLayout({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: GardenBackdrop(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
