import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../interest/application/incoming_interests_controller.dart';
import '../../interest/application/interest_controller.dart';
import 'public_profile_detail_page.dart';

class IncomingInterestsPage extends ConsumerWidget {
  const IncomingInterestsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(incomingInterestsControllerProvider);
    return Scaffold(
        appBar: AppBar(title: Text(l.incomingInterestsTitle)),
        body: ref.watch(premiumStateProvider)
            ? state.when(
                loading: () => const _Skeleton(),
                error: (_, __) => Center(
                    child: TextButton(
                        onPressed: () => ref
                            .read(incomingInterestsControllerProvider.notifier)
                            .retry(),
                        child: Text(l.discoveryIncomingRetry))),
                data: (data) => data.items.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.discoveryIncomingEmptyTitle),
                        const SizedBox(height: 8),
                        Text(l.discoveryIncomingEmptyBody),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l.discoveryIncomingContinue))
                      ]))
                    : ListView(children: [
                        for (final item in data.items)
                          _InterestCard(item: item),
                        if (data.hasMore)
                          TextButton(
                              onPressed: data.loadingMore
                                  ? null
                                  : () => ref
                                      .read(incomingInterestsControllerProvider
                                          .notifier)
                                      .loadMore(),
                              child: data.loadingMore
                                  ? const CircularProgressIndicator()
                                  : Text(l.discoveryLoadMore))
                      ]))
            : _FreeGate());
  }
}

class _FreeGate extends ConsumerWidget {
  const _FreeGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(incomingInterestSummaryProvider(
        ref.watch(authControllerProvider).user?.id ?? ''));
    return Center(
        child: summary.when(
            loading: () => const _Skeleton(),
            error: (_, __) => Text(l.discoveryIncomingUnavailable),
            data: (s) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.discoveryIncomingLikes(s.likes)),
                  if (s.specialInterests > 0)
                    Text(l
                        .discoveryIncomingSpecialInterests(s.specialInterests)),
                  const SizedBox(height: 16),
                  Text(l.incomingPremiumBody, textAlign: TextAlign.center),
                  FilledButton(
                      onPressed: () {}, child: Text(l.discoveryExplorePremium))
                ]))));
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({required this.item});
  final IncomingInterest item;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = item.profile;
    final special = item.interaction.type.name == 'specialInterest';
    return Semantics(
        label:
            '${p.displayName ?? l.discoveryAnonymous}${p.age == null ? '' : ', ${p.age}'}${p.city == null ? '' : ', ${p.city}'}. ${special ? l.discoverySpecialInterest : l.incomingLikeLabel}',
        child: Card(
            child: ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicProfileDetailPage(profile: p))),
                leading: (p.photoUrls ?? []).isEmpty
                    ? const Icon(Icons.person)
                    : CircleAvatar(
                        backgroundImage: NetworkImage(p.photoUrls!.first),
                        onBackgroundImageError: (_, __) {}),
                title: Text(p.displayName ?? l.discoveryAnonymous),
                subtitle: Text(special
                    ? '${l.discoverySpecialInterest}${item.interaction.reason == null ? '' : ' · ${l.discoverySpecialInterestReason(item.interaction.reason!)}'}'
                    : l.incomingLikeLabel),
                trailing: p.city == null ? null : Text(p.city!))));
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => ListView(children: [
        for (var i = 0; i < 3; i++)
          Container(
              height: 110,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: NoxColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(20)))
      ]);
}
