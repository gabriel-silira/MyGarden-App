import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../state/garden_controller.dart';
import '../theme/garden_theme.dart';
import 'plant_icon.dart';

String clockLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} • ${clockLabel(date)}';
String numberLabel(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
String conditionLabel(SoilCondition condition) => switch (condition) {
  SoilCondition.dry => 'Abaixo do limite',
  SoilCondition.balanced => 'Na faixa',
  SoilCondition.wet => 'Acima do alvo',
};

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), action!],
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = GardenTheme.isDark(context);
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF467D2B).withValues(alpha: .11),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: dark
                ? Border.all(
                    color: const Color(0xFF23513A).withValues(alpha: .8),
                  )
                : null,
            color: color,
            gradient: color != null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [const Color(0xFF073723), const Color(0xFF00281A)]
                        : [const Color(0xFFFDFFF9), const Color(0xFFE8F9DD)],
                  ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.error = false,
    this.icon = Icons.science_outlined,
  });
  final String text;
  final bool error;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? c.errorContainer : c.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.info_outline : icon,
            size: 20,
            color: error ? c.onErrorContainer : c.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: error ? c.onErrorContainer : c.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyGarden extends StatelessWidget {
  const EmptyGarden({super.key, required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      children: [
        Icon(
          Icons.yard_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Seu jardim começa aqui',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Cadastre uma planta para experimentar o monitoramento.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar planta'),
        ),
      ],
    ),
  );
}

class PlantSelector extends StatelessWidget {
  const PlantSelector({super.key, required this.controller});
  final GardenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = controller.selectedPlant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: LayoutBuilder(
            builder: (context, constraints) => Material(
              type: MaterialType.transparency,
              child: PopupMenuButton<String>(
                key: const ValueKey('plant-selector'),
                tooltip: '',
                enabled: !controller.busy && controller.plants.isNotEmpty,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  maxHeight: 320,
                ),
                color: colors.surfaceContainerLow,
                surfaceTintColor: Colors.transparent,
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                borderRadius: BorderRadius.circular(14),
                menuPadding: const EdgeInsets.all(8),
                onSelected: controller.selectPlant,
                itemBuilder: (_) => controller.plants.map((plant) {
                  final active = plant.id == controller.selectedId;
                  return PopupMenuItem<String>(
                    value: plant.id,
                    height: 48,
                    padding: EdgeInsets.zero,
                    child: Semantics(
                      selected: active,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? colors.primary.withValues(alpha: 0.10)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: PlantIconImage(icon: plant.icon, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plant.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: active
                                      ? colors.primary
                                      : colors.onSurface,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 18,
                              child: active
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: colors.primary,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                child: Semantics(
                  label:
                      'Planta acompanhada: ${selected?.name ?? 'Nenhuma planta'}',
                  excludeSemantics: true,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        PlantIconImage(
                          icon: selected?.icon ?? PlantIcon.mint,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Planta acompanhada',
                                style: theme.textTheme.labelSmall!.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected?.name ?? 'Selecionar planta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ConditionBadge extends StatelessWidget {
  const ConditionBadge({super.key, required this.condition});
  final SoilCondition condition;
  @override
  Widget build(BuildContext context) {
    final dark = GardenTheme.isDark(context);
    final good = condition == SoilCondition.balanced;
    final background = good
        ? (dark ? const Color(0xFF145820) : const Color(0xFFD3F6AF))
        : (dark ? const Color(0xFF604509) : const Color(0xFFFFEDBC));
    final foreground = good
        ? (dark ? const Color(0xFFD7FF9E) : const Color(0xFF164C10))
        : (dark ? const Color(0xFFFFE09A) : const Color(0xFF6D4100));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        conditionLabel(condition),
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ReadingSummary extends StatelessWidget {
  const ReadingSummary({
    super.key,
    required this.controller,
    this.showTimestamp = true,
  });
  final GardenController controller;
  final bool showTimestamp;
  @override
  Widget build(BuildContext context) {
    final r = controller.latest;
    if (r == null) {
      return const Notice(
        'Sem leitura atual. Atualize os dados ou escolha outro cenário.',
        icon: Icons.sensors_off,
      );
    }
    final condition = r.condition(controller.selectedPlant!.irrigation);
    final moisture = _MetricCard(
      label: 'Umidade',
      value: '${r.moisture.round()}%',
      icon: Icons.water_drop_outlined,
      iconColor: GardenTheme.isDark(context)
          ? const Color(0xFF45E0F3)
          : const Color(0xFF007F9E),
      badge: ConditionBadge(condition: condition),
    );
    final temperature = _MetricCard(
      label: 'Temperatura',
      value: '${numberLabel(r.temperature ?? 0)} °C',
      icon: Icons.thermostat_outlined,
      iconColor: GardenTheme.isDark(context)
          ? const Color(0xFFFF8659)
          : const Color(0xFFC44316),
      badge: Text('Simulada', style: Theme.of(context).textTheme.bodySmall),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final hasTemp =
                controller.temperatureEnabled && r.temperature != null;
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
            if (!hasTemp) return moisture;
            if (largeText || constraints.maxWidth < 270) {
              return Column(
                children: [moisture, const SizedBox(height: 12), temperature],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: moisture),
                const SizedBox(width: 12),
                Expanded(child: temperature),
              ],
            );
          },
        ),
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${controller.error == null ? 'Última leitura' : 'Último valor conhecido'}: ${clockLabel(r.timestamp)} • simulação',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.badge,
  });
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final Widget badge;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        badge,
      ],
    ),
  );
}

class EventList extends StatelessWidget {
  const EventList({super.key, required this.events});
  final List<IrrigationEvent> events;
  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Nenhuma irrigação neste período. Os eventos aparecerão após uma simulação.',
        ),
      );
    }
    return Column(
      children: events
          .map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.water_drop_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Irrigação ${e.mode == IrrigationMode.manual ? 'manual' : 'automática'} simulada',
              ),
              subtitle: Text(
                '${dateLabel(e.timestamp)} • ${e.duration.inSeconds}s • nenhum hardware acionado',
              ),
            ),
          )
          .toList(),
    );
  }
}
