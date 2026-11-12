import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'mint_symbol.dart';
import 'garden_widgets.dart';

class PlantArtwork extends StatelessWidget {
  const PlantArtwork({super.key, required this.plant, this.size = 88});
  final Plant plant;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: plant.id == 'mint'
        ? Image.asset(
            'assets/images/mint-cutout.png',
            fit: BoxFit.contain,
            cacheWidth: 320,
            semanticLabel: 'Hortelã',
            errorBuilder: (_, error, stack) => MintSymbol(size: size),
          )
        : MintSymbol(size: size * .75, label: 'Símbolo de ${plant.name}'),
  );
}

class PlantTile extends StatelessWidget {
  const PlantTile({
    super.key,
    required this.plant,
    required this.onTap,
    this.reading,
    this.compact = false,
    this.trailing,
  });
  final Plant plant;
  final SensorReading? reading;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(compact ? 12 : 16),
    onTap: onTap,
    child: Row(
      children: [
        ExcludeSemantics(
          child: PlantArtwork(plant: plant, size: compact ? 55 : 86),
        ),
        SizedBox(width: compact ? 10 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.name,
                style: compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge,
              ),
              if (plant.species.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    plant.species,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (reading != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ConditionBadge(
                    condition: reading!.condition(plant.irrigation),
                  ),
                ),
            ],
          ),
        ),
        trailing ??
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.chevron_right, size: 22),
            ),
      ],
    ),
  );
}
