import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../interest/application/interest_controller.dart';
import '../../interest/domain/interaction.dart';
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
                                    child: _Card(
                                      item,
                                      onPass: () => _sendInteraction(context,
                                          ref, item, InteractionType.pass),
                                      onLike: () => _sendInteraction(context,
                                          ref, item, InteractionType.like),
                                      onSpecialInterest: () =>
                                          _handleSpecialInterest(context, ref),
                                    )),
                              TextButton(
                                  onPressed: () => ref
                                      .read(
                                          discoveryControllerProvider.notifier)
                                      .loadMore(),
                                  child: Text(l.discoveryLoadMore)),
                            ]),
                    )))));
  }

  Future<void> _sendInteraction(BuildContext context, WidgetRef ref,
      PublicProfile profile, InteractionType type) async {
    final fromUid = ref.read(authControllerProvider).user?.id;
    if (fromUid == null) return;
    final sent = await ref
        .read(interestControllerProvider.notifier)
        .send(Interaction(fromUid: fromUid, toUid: profile.uid, type: type));
    if (sent) {
      ref.read(discoveryControllerProvider.notifier).removeProfile(profile.uid);
    }
  }

  void _handleSpecialInterest(BuildContext context, WidgetRef ref) {
    if (ref.read(premiumStateProvider)) {
      // TODO: Add Special Interest reason selection and submission.
      return;
    }
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: NoxColors.elevatedSurface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.discoverySpecialInterest,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(l.discoverySpecialInterestBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NoxColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () {},
                      child: Text(l.discoveryExplorePremium))),
              TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l.discoveryNotNow))
            ])));
  }
}

class _Card extends StatelessWidget {
  const _Card(this.profile,
      {required this.onPass,
      required this.onLike,
      required this.onSpecialInterest});
  final PublicProfile profile;
  final VoidCallback onPass, onLike, onSpecialInterest;
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
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        _ActionButton(
                            icon: Icons.close_rounded,
                            label: l.discoveryPass,
                            color: NoxColors.danger,
                            onPressed: onPass),
                        const SizedBox(width: 8),
                        _ActionButton(
                            icon: Icons.favorite_border_rounded,
                            label: l.discoveryLike,
                            color: NoxColors.cyan,
                            onPressed: onLike),
                        const SizedBox(width: 8),
                        _ActionButton(
                            icon: Icons.auto_awesome_rounded,
                            label: l.discoverySpecialInterest,
                            color: NoxColors.lavender,
                            onPressed: onSpecialInterest)
                      ])
                    ]))));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onPressed});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
      child: Semantics(
          button: true,
          label: label,
          child: Tooltip(
              message: label,
              child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon, color: color),
                      label: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color.withValues(alpha: .5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))))))));
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
