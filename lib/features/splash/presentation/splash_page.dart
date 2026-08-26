import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../../onboarding/application/onboarding_providers.dart';
import '../../onboarding/presentation/widgets/nox_atmosphere.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.minimumDisplayDuration = const Duration(milliseconds: 900),
  });

  final Duration minimumDisplayDuration;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _continueFromSplash();
  }

  Future<void> _continueFromSplash() async {
    final completed =
        await ref.read(onboardingCompletionStoreProvider).isCompleted();
    if (!mounted) return;
    _navigationTimer = Timer(widget.minimumDisplayDuration, () {
      if (mounted) context.go(completed ? '/auth' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final animation = reducedMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          );
    return Scaffold(
      body: Stack(
        children: [
          const NoxAtmosphere(variant: 0),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(animation),
                  child: Semantics(
                    header: true,
                    label: '${l10n.appName}. ${l10n.tagline}',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.appName,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.tagline,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: NoxColors.textSecondary,
                                    letterSpacing: .2,
                                  ),
                        ),
                      ],
                    ),
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
