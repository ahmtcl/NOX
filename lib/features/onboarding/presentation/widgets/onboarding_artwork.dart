import 'package:flutter/material.dart';

import '../../../../core/theme/nox_theme.dart';

class OnboardingArtwork extends StatelessWidget {
  const OnboardingArtwork({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final icon = switch (index) {
      0 => Icons.auto_awesome_rounded,
      1 => Icons.forum_outlined,
      2 => Icons.blur_on_rounded,
      _ => Icons.route_rounded,
    };
    return Semantics(
      label: 'NOX visual',
      child: Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NoxGradients.glow,
                  border: Border.all(
                    color: NoxColors.lavender.withValues(alpha: .32),
                  ),
                ),
              ),
              ...List.generate(
                3,
                (ring) => Transform.rotate(
                  angle: (index + ring) * .42,
                  child: Container(
                    width: 168.0 - ring * 28,
                    height: 168.0 - ring * 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(52),
                      border: Border.all(
                        color: ring == 1
                            ? NoxColors.cyan.withValues(alpha: .34)
                            : NoxColors.violet.withValues(alpha: .30),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NoxGradients.accent,
                ),
                child: Icon(icon, color: NoxColors.ink, size: 38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
