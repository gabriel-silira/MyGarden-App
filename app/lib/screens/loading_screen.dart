import 'package:flutter/material.dart';

import '../theme/garden_theme.dart';
import '../widgets/garden_backdrop.dart';
import '../widgets/mint_symbol.dart';

/// Visible only while the actual local initialization is running.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GardenBackdrop(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: BrandIcon(
                    dark: GardenTheme.isDark(context),
                    size: 112,
                  ),
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'My'),
                      TextSpan(
                        text: 'Garden',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Preparando seu jardim…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (MediaQuery.disableAnimationsOf(context))
                  const Icon(Icons.hourglass_empty, semanticLabel: 'Carregando')
                else
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      semanticsLabel: 'Carregando',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
