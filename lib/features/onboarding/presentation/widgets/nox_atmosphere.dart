import 'package:flutter/material.dart';

import '../../../../core/theme/nox_theme.dart';

class NoxAtmosphere extends StatelessWidget {
  const NoxAtmosphere({super.key, required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (variant) {
      0 => const Alignment(-0.7, -0.85),
      1 => const Alignment(0.8, -0.65),
      2 => const Alignment(-0.8, 0.55),
      _ => const Alignment(0.7, 0.7),
    };
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: NoxGradients.atmosphere),
          ),
          Align(
            alignment: alignment,
            child: Container(
              width: 310,
              height: 310,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: NoxGradients.glow,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: -0.45 + (variant * 0.16),
              child: Container(
                width: 240,
                height: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(
                    color: NoxColors.lavender.withValues(alpha: .18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NoxColors.violet.withValues(alpha: .16),
                      NoxColors.cyan.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
