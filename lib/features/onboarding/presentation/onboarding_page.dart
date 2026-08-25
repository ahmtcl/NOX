import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/onboarding_providers.dart';
import 'widgets/nox_atmosphere.dart';
import 'widgets/onboarding_artwork.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _pageCount = 4;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(onboardingCompletionStoreProvider).markCompleted();
    if (mounted) context.go('/auth');
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 450),
            child: NoxAtmosphere(key: ValueKey(_page), variant: _page),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: l10n.skip,
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(l10n.skip),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pageCount,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) =>
                        _OnboardingSlide(index: index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: _page == 0
                            ? null
                            : TextButton(
                                onPressed: () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                ),
                                child: Text(l10n.back),
                              ),
                      ),
                      Expanded(
                        child: _PageIndicator(
                          current: _page,
                          count: _pageCount,
                        ),
                      ),
                      SizedBox(
                        width: 132,
                        child: Semantics(
                          button: true,
                          label: _page == _pageCount - 1
                              ? l10n.startNox
                              : l10n.next,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: NoxColors.violet,
                              foregroundColor: NoxColors.textPrimary,
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(
                              _page == _pageCount - 1
                                  ? l10n.startNox
                                  : l10n.next,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: constraints.maxHeight < 580 ? 3 : 4,
              child: OnboardingArtwork(index: index),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.onboardingTitle(index),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                l10n.onboardingBody(index),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: NoxColors.textSecondary,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${current + 1} / $count',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == current ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: index == current
                    ? NoxColors.cyan
                    : NoxColors.textSecondary.withValues(alpha: .35),
              ),
            ),
          ),
        ),
      );
}
