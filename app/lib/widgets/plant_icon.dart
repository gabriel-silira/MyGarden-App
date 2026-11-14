import 'package:flutter/material.dart';

import '../domain/models.dart';

extension PlantIconVisuals on PlantIcon {
  String get label => switch (this) {
    PlantIcon.mint => 'Hortelã',
    PlantIcon.lemonBalm => 'Cidreira',
    PlantIcon.chives => 'Cebolinha',
  };

  String get asset => switch (this) {
    PlantIcon.mint => 'assets/images/plant-hortela.png',
    PlantIcon.lemonBalm => 'assets/images/plant-cidreira.png',
    PlantIcon.chives => 'assets/images/plant-cebolinha.png',
  };
}

class PlantIconImage extends StatelessWidget {
  const PlantIconImage({super.key, required this.icon, this.size = 88});
  final PlantIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    icon.asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    semanticLabel: 'Ícone de ${icon.label}',
    errorBuilder: (_, error, stack) => SizedBox.square(
      dimension: size,
      child: Icon(
        Icons.eco_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class PlantIconPicker extends StatelessWidget {
  const PlantIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final PlantIcon value;
  final ValueChanged<PlantIcon> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ícone da planta', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          'Escolha a imagem que aparece no seu jardim.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                MediaQuery.textScalerOf(context).scale(14) > 20 ||
                    constraints.maxWidth < 240
                ? 2
                : 3;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlantIcon.values.map((icon) {
                final selected = value == icon;
                return SizedBox(
                  width: width,
                  child: Semantics(
                    button: true,
                    selected: selected,
                    inMutuallyExclusiveGroup: true,
                    label: 'Ícone ${icon.label}',
                    child: Material(
                      color: selected
                          ? colors.primaryContainer
                          : colors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: selected
                              ? colors.primary
                              : colors.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('plant-icon-${icon.name}'),
                        onTap: () => onChanged(icon),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: selected
                                        ? colors.primary
                                        : colors.outline,
                                  ),
                                ),
                                PlantIconImage(icon: icon, size: 64),
                                const SizedBox(height: 6),
                                Text(
                                  icon.label,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium!.copyWith(
                                    color: selected
                                        ? colors.onPrimaryContainer
                                        : colors.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
