import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/domain/chat_repository.dart';
import '../../chat/presentation/chat_page.dart';
import '../../discovery/application/discovery_controller.dart';
import '../../discovery/domain/public_profile.dart';
import '../../discovery/presentation/public_profile_detail_page.dart';
import '../application/match_controller.dart';
import '../domain/match.dart';

final matchProfilesProvider = FutureProvider.autoDispose
    .family<Map<String, PublicProfile>, List<NoxMatch>>((ref, matches) {
  final uid = ref.watch(authControllerProvider).user?.id;
  final profileIds = {
    for (final match in matches)
      if (uid != null) _otherUserId(match, uid),
  };
  return ref
      .read(discoveryRepositoryProvider)
      .getPublicProfilesByIds(profileIds);
});

String _otherUserId(NoxMatch match, String currentUid) =>
    match.userAUid == currentUid ? match.userBUid : match.userAUid;

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
          data: (matches) =>
              matches.isEmpty ? _EmptyMessage() : _Profiles(matches: matches),
        ),
      ),
    );
  }
}

class _Profiles extends ConsumerWidget {
  const _Profiles({required this.matches});
  final List<NoxMatch> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(matchProfilesProvider(matches));
    return profiles.when(
      loading: () => const _CardSkeleton(),
      error: (_, __) => _Message(
        title: l.matchesUnavailable,
        actionLabel: l.matchesRetry,
        onPressed: () => ref.invalidate(matchProfilesProvider(matches)),
      ),
      data: (byUid) {
        final currentUid = ref.watch(authControllerProvider).user?.id;
        final orderedProfiles = [
          for (final match in matches)
            if (currentUid != null)
              if (byUid[_otherUserId(match, currentUid)] case final profile?)
                profile,
        ];
        final matchesByOtherUid = {
          for (final match in matches)
            if (currentUid != null) _otherUserId(match, currentUid): match,
        };
        return orderedProfiles.isEmpty
            ? const _EmptyMessage()
            : _MatchList(
                profiles: orderedProfiles,
                matchesByOtherUid: matchesByOtherUid,
                currentUid: currentUid!,
              );
      },
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Message(
      title: l.matchesEmptyTitle,
      body: l.matchesEmptyBody,
      actionLabel: l.matchesContinueDiscovering,
      onPressed: () => context.go('/home'),
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
  const _MatchList({
    required this.profiles,
    required this.matchesByOtherUid,
    required this.currentUid,
  });
  final List<PublicProfile> profiles;
  final Map<String, NoxMatch> matchesByOtherUid;
  final String currentUid;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _MatchCard(
          profile: profiles[index],
          match: matchesByOtherUid[profiles[index].uid]!,
          currentUid: currentUid,
        ),
      );
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({
    required this.profile,
    required this.match,
    required this.currentUid,
  });
  final PublicProfile profile;
  final NoxMatch match;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final name = profile.displayName ?? l.discoveryAnonymous;
    final details = [
      if (profile.age != null) '${profile.age}',
      if (profile.city != null) profile.city!,
    ];
    return Semantics(
      button: true,
      label: l.matchesCardSemantics(name, profile.age, profile.city),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PublicProfileDetailPage(profile: profile))),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _ProfilePhoto(profile: profile),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(details.join(' · '),
                            style: const TextStyle(
                                color: NoxColors.textSecondary)),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(chatRepositoryProvider)
                              .createConversationIfNeeded(
                                match.userAUid,
                                match.userBUid,
                              );
                          if (!context.mounted) return;
                          context.push(
                            '/chat',
                            extra: ChatRouteArgs(
                              session: ChatSession(
                                userAUid: match.userAUid,
                                userBUid: match.userBUid,
                                currentUserUid: currentUid,
                              ),
                              otherUserName: name,
                            ),
                          );
                        },
                        child: const Text('Sohbet aç'),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profile});
  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.photoUrls?.firstOrNull;
    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: url == null || url.isEmpty
            ? const _PhotoFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null ? child : const _PhotoFallback(),
                errorBuilder: (_, __, ___) => const _PhotoFallback(),
              ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: NoxColors.elevatedSurface,
        child: Center(child: Icon(Icons.person_outline)),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        key: const ValueKey('match-card-skeleton'),
        padding: const EdgeInsets.all(20),
        children: List.generate(
            3,
            (_) => Container(
                  height: 88,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: NoxColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                )),
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
