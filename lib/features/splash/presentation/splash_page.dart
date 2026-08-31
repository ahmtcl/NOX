import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/nox_stripe_background.dart';
import '../../onboarding/application/onboarding_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.minimumDisplayDuration = const Duration(milliseconds: 2400),
  });

  final Duration minimumDisplayDuration;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F0FC),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const NoxStripeBackground(),
            Center(
              child: FractionallySizedBox(
                widthFactor: .86,
                child: Image.asset(
                  'assets/branding/nox_brand_overlay.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
