import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/match_controller.dart';
import '../domain/match.dart';

class MatchPage extends ConsumerWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(matchControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.matchesTitle)),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
        child: state.when(
          loading: () => _Loading(label: l.matchesLoading),
          error: (_, __) => _Message(
            title: l.matchesUnavailable,
            actionLabel: l.matchesRetry,
            onPressed: () => ref.read(matchControllerProvider.notifier).retry(),
          ),
          data: (matches) => matches.isEmpty
              ? _Message(
                  title: l.matchesEmptyTitle,
                  body: l.matchesEmptyBody,
                  actionLabel: l.matchesContinueDiscovering,
                  onPressed: () => context.go('/home'),
                )
              : _MatchList(matches: matches),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ]),
      );
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches});
  final List<NoxMatch> matches;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => Card(
          child: ListTile(
            title: Text(matches[index].matchId),
            subtitle: Text(matches[index].status.name),
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    this.body,
    required this.actionLabel,
    required this.onPressed,
  });
  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: NoxColors.elevatedSurface.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title, textAlign: TextAlign.center),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(body!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: onPressed, child: Text(actionLabel)),
              ]),
            ),
          ),
        ),
      );
}
