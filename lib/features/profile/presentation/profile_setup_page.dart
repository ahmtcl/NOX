import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/profile_setup_controller.dart';
import '../domain/profile_setup_catalog.dart';
import '../domain/profile_setup_draft.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  static const _personalAnswerLimit = 180;
  final _answerController = TextEditingController();
  var _step = 0;
  var _didSeedAnswer = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _moveTo(int target) {
    setState(() => _step = target.clamp(0, profileQuestions.length + 1));
  }

  void _select(ProfileQuestionDefinition definition, String choiceId) {
    final selected = ref
            .read(profileSetupControllerProvider)
            .valueOrNull
            ?.choicesFor(definition.question) ??
        const <String>{};
    if (!selected.contains(choiceId) && selected.length >= definition.maximum) {
      return;
    }
    if (!MediaQuery.of(context).disableAnimations)
      HapticFeedback.selectionClick();
    ref.read(profileSetupControllerProvider.notifier).toggleChoice(
          definition.question,
          choiceId,
          maximum: definition.maximum,
        );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileSetupControllerProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);
    if (draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_didSeedAnswer) {
      _answerController.text = draft.personalAnswer;
      _didSeedAnswer = true;
    }
    final totalSteps = profileQuestions.length + 1;
    final progressStep = _step.clamp(0, totalSteps);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: NoxGradients.atmosphere),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressHeader(step: progressStep, total: totalSteps),
                    const SizedBox(height: 24),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.of(context).disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _content(context, l10n, draft),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Actions(
                      step: _step,
                      draft: draft,
                      saveState: ref.watch(profileSetupSaveControllerProvider),
                      onBack: _step == 0 ? null : () => _moveTo(_step - 1),
                      onSkip:
                          _step < totalSteps ? () => _moveTo(_step + 1) : null,
                      onNext: () => _next(draft),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, AppLocalizations l10n, ProfileSetupDraft draft) {
    if (_step < profileQuestions.length) {
      final definition = profileQuestions[_step];
      return _QuestionStep(
        definition: definition,
        selected: draft.choicesFor(definition.question),
        onSelect: (id) => _select(definition, id),
      );
    }
    if (_step == profileQuestions.length) {
      return _PersonalStep(
        controller: _answerController,
        limit: _personalAnswerLimit,
        onChanged: (value) => ref
            .read(profileSetupControllerProvider.notifier)
            .setPersonalAnswer(value),
      );
    }
    return _SummaryStep(draft: draft);
  }

  Future<void> _next(ProfileSetupDraft draft) async {
    if (_step < profileQuestions.length) {
      final definition = profileQuestions[_step];
      if (draft.choicesFor(definition.question).length < definition.minimum)
        return;
      _moveTo(_step + 1);
      return;
    }
    if (_step == profileQuestions.length) {
      _moveTo(_step + 1);
      return;
    }
    final didSave = await ref
        .read(profileSetupSaveControllerProvider.notifier)
        .complete(ref.read(authControllerProvider).user);
    if (!mounted) return;
    if (didSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).profileCompleted)),
      );
      context.go('/home');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileSaveFailed)),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('NOX',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(letterSpacing: 4, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(
              '${step == total ? total : step + 1} / $total',
              semanticsLabel:
                  'Progress ${step == total ? total : step + 1} of $total',
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: step == total ? 1 : (step + 1) / total,
              minHeight: 6,
            ),
          ),
        ],
      );
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep(
      {required this.definition,
      required this.selected,
      required this.onSelect});
  final ProfileQuestionDefinition definition;
  final Set<String> selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.profileDiscoveryEyebrow,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: NoxColors.cyan, letterSpacing: 1.4)),
        const SizedBox(height: 10),
        Text(l10n.profileQuestion(definition.question.name),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(l10n.selectionHint(definition.minimum, definition.maximum),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NoxColors.textSecondary)),
        const SizedBox(height: 6),
        Text(l10n.selectedCount(selected.length, definition.maximum),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: NoxColors.lavender)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 500 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: definition.choices.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: columns == 2 ? 3.6 : 4.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemBuilder: (context, index) {
              final choice = definition.choices[index];
              return _ChoiceCard(
                  choice: choice,
                  label: l10n.profileOption(choice.id),
                  selected: selected.contains(choice.id),
                  onTap: () => onSelect(choice.id));
            },
          );
        }),
      ]),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.choice,
      required this.label,
      required this.selected,
      required this.onTap});
  final ProfileChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? NoxColors.violet.withValues(alpha: .28)
                    : NoxColors.elevatedSurface.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: selected
                        ? NoxColors.cyan
                        : NoxColors.lavender.withValues(alpha: .16),
                    width: selected ? 1.5 : 1),
              ),
              child: Row(children: [
                Text(choice.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (selected)
                  const Icon(Icons.check_circle, color: NoxColors.cyan),
              ]),
            ),
          ),
        ),
      );
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep(
      {required this.controller, required this.limit, required this.onChanged});
  final TextEditingController controller;
  final int limit;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.profileDiscoveryEyebrow,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: NoxColors.cyan, letterSpacing: 1.4)),
      const SizedBox(height: 10),
      Text(l10n.profilePersonalTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(l10n.profilePersonalBody,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: NoxColors.textSecondary)),
      const SizedBox(height: 24),
      TextField(
          controller: controller,
          maxLength: limit,
          minLines: 5,
          maxLines: 7,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
              hintText: l10n.profilePersonalHint,
              alignLabelWithHint: true,
              filled: true,
              fillColor: NoxColors.elevatedSurface.withValues(alpha: .82),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)))),
      Text(l10n.charactersRemaining(limit - controller.text.length),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: NoxColors.textSecondary)),
    ]));
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.draft});
  final ProfileSetupDraft draft;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries =
        draft.selections.entries.where((entry) => entry.value.isNotEmpty);
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.profileSummaryEyebrow,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: NoxColors.cyan, letterSpacing: 1.4)),
      const SizedBox(height: 10),
      Text(l10n.profileSummaryTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(l10n.profileSummaryBody,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: NoxColors.textSecondary)),
      const SizedBox(height: 24),
      ...entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SummaryGroup(
              title: l10n.profileQuestion(entry.key.name),
              values: entry.value.map(l10n.profileOption).toList()))),
      if (draft.personalAnswer.trim().isNotEmpty)
        _SummaryGroup(
            title: l10n.profilePersonalTitle,
            values: [draft.personalAnswer.trim()]),
    ]));
  }
}

class _SummaryGroup extends StatelessWidget {
  const _SummaryGroup({required this.title, required this.values});
  final String title;
  final List<String> values;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: NoxColors.elevatedSurface.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(values.join(' · '),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NoxColors.textSecondary))
      ]));
}

class _Actions extends StatelessWidget {
  const _Actions(
      {required this.step,
      required this.draft,
      required this.saveState,
      required this.onBack,
      required this.onSkip,
      required this.onNext});
  final int step;
  final ProfileSetupDraft draft;
  final ProfileSetupSaveState saveState;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSummary = step > profileQuestions.length;
    final definition =
        step < profileQuestions.length ? profileQuestions[step] : null;
    final canContinue = definition == null ||
        draft.choicesFor(definition.question).length >= definition.minimum;
    return Row(children: [
      if (onBack != null)
        TextButton(onPressed: onBack, child: Text(l10n.profileBack)),
      const Spacer(),
      if (!isSummary && onSkip != null)
        TextButton(onPressed: onSkip, child: Text(l10n.profileSkip)),
      const SizedBox(width: 8),
      FilledButton(
          onPressed: canContinue && !saveState.isSaving ? onNext : null,
          child: saveState.isSaving && isSummary
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(l10n.profileSaving)
                ])
              : Text(isSummary ? l10n.profileFinish : l10n.profileContinue)),
    ]);
  }
}
