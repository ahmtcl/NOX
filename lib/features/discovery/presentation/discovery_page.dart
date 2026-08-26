import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/discovery_controller.dart';
import '../domain/public_profile.dart';
import 'public_profile_detail_page.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(discoveryControllerProvider);
    return Scaffold(
        body: DecoratedBox(
            decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
            child: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: state.when(
                      loading: () => const _Skeleton(),
                      error: (_, __) => _Message(
                          l.discoveryError,
                          null,
                          l.profileRetry,
                          () => ref
                              .read(discoveryControllerProvider.notifier)
                              .retry()),
                      data: (items) => items.isEmpty
                          ? _Message(
                              l.discoveryEmpty,
                              l.discoveryEmptyBody,
                              l.profileRetry,
                              () => ref
                                  .read(discoveryControllerProvider.notifier)
                                  .retry())
                          : ListView(children: [
                              Text(l.discoveryTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 18),
                              for (final item in items)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _Card(item)),
                              TextButton(
                                  onPressed: () => ref
                                      .read(
                                          discoveryControllerProvider.notifier)
                                      .loadMore(),
                                  child: Text(l.discoveryLoadMore)),
                            ]),
                    )))));
  }
}

class _Card extends StatelessWidget {
  const _Card(this.profile);
  final PublicProfile profile;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
        button: true,
        label: l.discoverySemantic(profile.displayName, profile.age,
            profile.city, profile.personalityTraits ?? []),
        child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PublicProfileDetailPage(profile: profile))),
            borderRadius: BorderRadius.circular(26),
            child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: NoxColors.elevatedSurface.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(26)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((profile.photoUrls ?? []).isNotEmpty)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(profile.photoUrls!.first,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 220,
                                    child: Center(
                                        child: Icon(Icons.person_outline,
                                            size: 56))))),
                      const SizedBox(height: 12),
                      Text(
                          '${profile.displayName ?? l.discoveryAnonymous}${profile.age == null ? '' : ', ${profile.age}'}',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (profile.city != null)
                        Text(profile.city!,
                            style: const TextStyle(color: NoxColors.cyan)),
                      if (profile.bio != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(profile.bio!)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final tag
                            in (profile.personalityTraits ?? []).take(4))
                          Chip(label: Text(tag))
                      ])
                    ]))));
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => ListView(children: [
        for (var i = 0; i < 2; i++)
          Container(
              height: 330,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: NoxColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(26)))
      ]);
}

class _Message extends StatelessWidget {
  const _Message(this.title, this.body, this.action, this.onAction);
  final String title, action;
  final String? body;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome_outlined,
            size: 44, color: NoxColors.lavender),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center),
        if (body != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(body!, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onAction, child: Text(action))
      ]));
}
