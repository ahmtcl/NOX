import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../safety/application/safety_controller.dart';
import '../../safety/domain/safety_models.dart';
import '../domain/public_profile.dart';

class PublicProfileDetailPage extends ConsumerStatefulWidget {
  const PublicProfileDetailPage({super.key, required this.profile});
  final PublicProfile profile;
  @override
  ConsumerState<PublicProfileDetailPage> createState() => _DetailState();
}

class _DetailState extends ConsumerState<PublicProfileDetailPage> {
  void _options() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.safetyOptions),
              ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: Text(l.discoveryBlock),
                  onTap: () {
                    Navigator.pop(context);
                    _block();
                  }),
              ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(l.discoveryReport),
                  onTap: () {
                    Navigator.pop(context);
                    _report();
                  }),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.safetyCancel))
            ])));
  }

  Future<void> _block() async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: Text(l.safetyBlockTitle),
                content: Text(l.safetyBlockBody),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.safetyCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.discoveryBlock))
                ]));
    if (yes != true) return;
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    final ok = await ref
        .read(safetyControllerProvider.notifier)
        .block(BlockedUser(blockerUid: uid, blockedUid: widget.profile.uid));
    if (!mounted) return;
    messenger.showSnackBar(
        SnackBar(content: Text(ok ? l.safetyBlocked : l.safetyFailed)));
    if (ok) navigator.pop();
  }

  void _report() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ReportForm(profile: widget.profile));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text(l.discoveryProfile), actions: [
          IconButton(
              tooltip: l.safetyOptions,
              onPressed: _options,
              icon: const Icon(Icons.more_horiz))
        ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(
              '${widget.profile.displayName ?? l.discoveryAnonymous}${widget.profile.age == null ? '' : ', ${widget.profile.age}'}',
              style: Theme.of(context).textTheme.headlineMedium),
          if (widget.profile.city != null) Text(widget.profile.city!),
          if (widget.profile.bio != null) ...[
            const SizedBox(height: 12),
            Text(widget.profile.bio!)
          ],
          const SizedBox(height: 20),
          Wrap(spacing: 8, children: [
            for (final x in widget.profile.personalityTraits ?? [])
              Chip(label: Text(x))
          ])
        ]));
  }
}

class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({required this.profile});
  final PublicProfile profile;
  @override
  ConsumerState<_ReportForm> createState() => _ReportState();
}

class _ReportState extends ConsumerState<_ReportForm> {
  ReportReason? reason;
  var also = false;
  final details = TextEditingController();
  var sending = false;
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    return SafeArea(
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(l.safetyReportTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(l.safetyConfidential),
                  const SizedBox(height: 12),
                  RadioGroup<ReportReason>(
                    groupValue: reason,
                    onChanged: (value) => setState(() => reason = value),
                    child: Column(children: [
                      for (final r in ReportReason.values)
                        RadioListTile<ReportReason>(
                            value: r, title: Text(l.reportReason(r))),
                    ]),
                  ),
                  if (reason != null) ...[
                    Text(l.safetyDetails),
                    TextField(
                        controller: details,
                        maxLength: 500,
                        maxLines: 4,
                        decoration:
                            InputDecoration(hintText: l.safetyDetailsHint))
                  ],
                  SwitchListTile(
                      value: also,
                      onChanged: (v) => setState(() => also = v),
                      title: Text(l.safetyAlsoBlock)),
                  FilledButton(
                      onPressed: reason == null || sending
                          ? null
                          : () async {
                              setState(() => sending = true);
                              final uid =
                                  ref.read(authControllerProvider).user?.id;
                              final ok = uid != null &&
                                  await ref
                                      .read(safetyControllerProvider.notifier)
                                      .report(
                                          UserReport(
                                              reporterUid: uid,
                                              reportedUid: widget.profile.uid,
                                              reason: reason!,
                                              details: details.text),
                                          alsoBlock: also);
                              if (!mounted) return;
                              setState(() => sending = false);
                              if (ok) {
                                navigator.pop();
                                messenger.showSnackBar(
                                    SnackBar(content: Text(l.safetyReceived)));
                              } else {
                                messenger.showSnackBar(
                                    SnackBar(content: Text(l.safetyFailed)));
                              }
                            },
                      child: Text(l.safetySubmit))
                ]))));
  }
}
