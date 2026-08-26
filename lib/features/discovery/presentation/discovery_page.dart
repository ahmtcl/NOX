import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../interest/application/interest_controller.dart';
import '../../interest/domain/interaction.dart';
import '../../interest/domain/interest_repository.dart';
import '../application/discovery_controller.dart';
import '../domain/public_profile.dart';
import 'public_profile_detail_page.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(discoveryControllerProvider);
    final uid = ref.watch(authControllerProvider).user?.id;
    final incoming = uid == null
        ? const AsyncData<IncomingInterestSummary>(IncomingInterestSummary())
        : ref.watch(incomingInterestSummaryProvider(uid));
    final isPremium = ref.watch(premiumStateProvider);
    return Scaffold(
        body: DecoratedBox(
            decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
            child: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: state.when(
                      loading: () => ListView(children: [
                        _IncomingInterestCard(
                            incoming: incoming,
                            isPremium: isPremium,
                            onRetry: () => _retryIncoming(ref, uid),
                            onCta: () => _showIncomingPlaceholder(context)),
                        const SizedBox(height: 18),
                        const _Skeleton()
                      ]),
                      error: (_, __) => ListView(children: [
                        _IncomingInterestCard(
                            incoming: incoming,
                            isPremium: isPremium,
                            onRetry: () => _retryIncoming(ref, uid),
                            onCta: () => _showIncomingPlaceholder(context)),
                        const SizedBox(height: 24),
                        _Message(
                            l.discoveryError,
                            null,
                            l.profileRetry,
                            () => ref
                                .read(discoveryControllerProvider.notifier)
                                .retry())
                      ]),
                      data: (items) => items.isEmpty
                          ? ListView(children: [
                              _IncomingInterestCard(
                                  incoming: incoming,
                                  isPremium: isPremium,
                                  onRetry: () => _retryIncoming(ref, uid),
                                  onCta: () =>
                                      _showIncomingPlaceholder(context)),
                              const SizedBox(height: 24),
                              _Message(
                                  l.discoveryEmpty,
                                  l.discoveryEmptyBody,
                                  l.profileRetry,
                                  () => ref
                                      .read(
                                          discoveryControllerProvider.notifier)
                                      .retry())
                            ])
                          : ListView(children: [
                              Text(l.discoveryTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 18),
                              _IncomingInterestCard(
                                  incoming: incoming,
                                  isPremium: isPremium,
                                  onRetry: () => _retryIncoming(ref, uid),
                                  onCta: () =>
                                      _showIncomingPlaceholder(context)),
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
                                          _handleSpecialInterest(
                                              context, ref, item),
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

  void _retryIncoming(WidgetRef ref, String? uid) {
    if (uid != null) ref.invalidate(incomingInterestSummaryProvider(uid));
  }

  void _showIncomingPlaceholder(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).discoveryIncomingPlaceholder)));

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

  Future<void> _handleSpecialInterest(
      BuildContext context, WidgetRef ref, PublicProfile profile) async {
    if (ref.read(premiumStateProvider)) {
      final sent = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: NoxColors.elevatedSurface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          builder: (_) => _SpecialInterestReasonSheet(
              onSubmit: (reason) =>
                  _submitSpecialInterest(ref, profile, reason)));
      if (sent == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context).discoverySpecialInterestSent)));
      }
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
              const SizedBox(height: 8),
              Text(l.discoverySpecialInterestPremiumNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NoxColors.lavender)),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l.discoveryPremiumPlaceholder)));
                      },
                      child: Text(l.discoveryExplorePremium))),
              TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l.discoveryNotNow))
            ])));
  }

  Future<bool> _submitSpecialInterest(WidgetRef ref, PublicProfile profile,
      SpecialInterestReason reason) async {
    final fromUid = ref.read(authControllerProvider).user?.id;
    if (fromUid == null) return false;
    final sent = await ref.read(interestControllerProvider.notifier).send(
        Interaction(
            fromUid: fromUid,
            toUid: profile.uid,
            type: InteractionType.specialInterest,
            reason: reason));
    if (sent) {
      ref.read(discoveryControllerProvider.notifier).removeProfile(profile.uid);
    }
    return sent;
  }
}

class _IncomingInterestCard extends StatelessWidget {
  const _IncomingInterestCard(
      {required this.incoming,
      required this.isPremium,
      required this.onRetry,
      required this.onCta});
  final AsyncValue<IncomingInterestSummary> incoming;
  final bool isPremium;
  final VoidCallback onRetry, onCta;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return incoming.when(
        loading: () => const _IncomingInterestSkeleton(),
        error: (_, __) => Semantics(
            label:
                '${l.discoveryIncomingTitle}. ${l.discoveryIncomingUnavailable}',
            child: _IncomingInterestSurface(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l.discoveryIncomingTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l.discoveryIncomingUnavailable,
                      style: const TextStyle(color: NoxColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: onRetry, child: Text(l.discoveryIncomingRetry))
                ]))),
        data: (summary) => Semantics(
            label: l.discoveryIncomingSemantic(
                summary.likes, summary.specialInterests, summary.isEmpty),
            child: _IncomingInterestSurface(
                child: summary.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(l.discoveryIncomingTitle,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Text(l.discoveryIncomingEmptyTitle),
                            const SizedBox(height: 4),
                            Text(l.discoveryIncomingEmptyBody,
                                style: const TextStyle(
                                    color: NoxColors.textSecondary)),
                            const SizedBox(height: 12),
                            _IncomingCta(
                                label: l.discoveryIncomingContinue,
                                onPressed: onCta)
                          ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(l.discoveryIncomingTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Text(l.discoveryIncomingLikes(summary.likes)),
                            if (summary.specialInterests > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                  l.discoveryIncomingSpecialInterests(
                                      summary.specialInterests),
                                  style: const TextStyle(
                                      color: NoxColors.lavender))
                            ],
                            const SizedBox(height: 12),
                            Align(
                                alignment: Alignment.centerRight,
                                child: _IncomingCta(
                                    label: isPremium
                                        ? l.discoveryIncomingViewPremium
                                        : l.discoveryIncomingView,
                                    onPressed: onCta))
                          ]))));
  }
}

class _IncomingInterestSurface extends StatelessWidget {
  const _IncomingInterestSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: NoxColors.elevatedSurface.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NoxColors.lavender.withValues(alpha: .32)),
          boxShadow: [
            BoxShadow(
                color: NoxColors.violet.withValues(alpha: .12), blurRadius: 18)
          ]),
      child: Padding(padding: const EdgeInsets.all(18), child: child));
}

class _IncomingInterestSkeleton extends StatelessWidget {
  const _IncomingInterestSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
      label: AppLocalizations.of(context).discoveryIncomingTitle,
      child: _IncomingInterestSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            height: 18,
            width: 140,
            decoration: BoxDecoration(
                color: NoxColors.surface,
                borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 14),
        Container(
            height: 14,
            width: 210,
            decoration: BoxDecoration(
                color: NoxColors.surface,
                borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 8),
        Container(
            height: 14,
            width: 170,
            decoration: BoxDecoration(
                color: NoxColors.surface,
                borderRadius: BorderRadius.circular(8)))
      ])));
}

class _IncomingCta extends StatelessWidget {
  const _IncomingCta({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 48, child: TextButton(onPressed: onPressed, child: Text(label)));
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

class _SpecialInterestReasonSheet extends StatefulWidget {
  const _SpecialInterestReasonSheet({required this.onSubmit});
  final Future<bool> Function(SpecialInterestReason reason) onSubmit;

  @override
  State<_SpecialInterestReasonSheet> createState() =>
      _SpecialInterestReasonSheetState();
}

class _SpecialInterestReasonSheetState
    extends State<_SpecialInterestReasonSheet> {
  static const _reasons = [
    (SpecialInterestReason.personality, '🧠'),
    (SpecialInterestReason.humor, '😂'),
    (SpecialInterestReason.music, '🎵'),
    (SpecialInterestReason.lifestyle, '🌎'),
    (SpecialInterestReason.profileEnergy, '📸'),
    (SpecialInterestReason.overall, '❤️'),
  ];
  SpecialInterestReason? _selected;
  var _submitting = false;

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);
    final sent = await widget.onSubmit(reason);
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context).discoverySpecialInterestFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.discoverySpecialInterestReasonTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l.discoverySpecialInterestReasonBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NoxColors.textSecondary)),
              const SizedBox(height: 20),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final option in _reasons)
                  _ReasonOption(
                      reason: option.$1,
                      emoji: option.$2,
                      selected: _selected == option.$1,
                      onTap: _submitting
                          ? null
                          : () => setState(() => _selected = option.$1))
              ]),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                      onPressed:
                          _selected == null || _submitting ? null : _submit,
                      child: _submitting
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              const SizedBox(width: 12),
                              Text(l.discoverySpecialInterestLoading)
                            ])
                          : Text(l.discoverySpecialInterestSend)))
            ])));
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption(
      {required this.reason,
      required this.emoji,
      required this.selected,
      required this.onTap});
  final SpecialInterestReason reason;
  final String emoji;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = selected ? NoxColors.lavender : NoxColors.textSecondary;
    return Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label: l.discoveryReasonSelectionSemantics(reason, selected),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
                duration: Duration.zero,
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: selected
                        ? NoxColors.violet.withValues(alpha: .24)
                        : NoxColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? NoxColors.lavender
                            : color.withValues(alpha: .3)),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: NoxColors.violet.withValues(alpha: .22),
                                blurRadius: 14)
                          ]
                        : null),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(emoji),
                  const SizedBox(width: 8),
                  Text(l.discoverySpecialInterestReason(reason),
                      style: TextStyle(color: color))
                ]))));
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Column(children: [
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
