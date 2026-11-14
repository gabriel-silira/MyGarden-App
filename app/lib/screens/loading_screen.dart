import 'package:flutter/material.dart';

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
                  child: MintSymbol(
                    color: Theme.of(context).colorScheme.primary,
                    size: 96,
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
                const SizedBox(height: 40),
                if (MediaQuery.disableAnimationsOf(context))
                  const Icon(Icons.hourglass_empty, semanticLabel: 'Carregando')
                else
                  SizedBox(
                    width: 144,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .12),
                      semanticsLabel: 'Carregando',
                    ),
                  ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Preparando seu jardim…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
