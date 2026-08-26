import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/public_profile.dart';

class PublicProfileDetailPage extends StatelessWidget {
  const PublicProfileDetailPage({super.key, required this.profile});
  final PublicProfile profile;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = <String, List<String>?>{
      l.discoveryPersonality: profile.personalityTraits,
      l.discoveryFreeTime: profile.freeTimePreferences,
      l.discoveryDate: profile.datePreferences,
      l.discoveryConversation: profile.conversationStyles,
      l.discoveryLifeGoals: profile.lifeGoals,
      l.discoveryMusic: profile.musicPreferences,
      l.discoveryTravel: profile.travelStyles,
      l.discoveryConnection: profile.connectionValues
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.discoveryProfile)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(
              '${profile.displayName ?? l.discoveryAnonymous}${profile.age == null ? '' : ', ${profile.age}'}',
              style: Theme.of(context).textTheme.headlineMedium),
          if (profile.city != null) Text(profile.city!),
          if (profile.bio != null) ...[
            const SizedBox(height: 12),
            Text(profile.bio!)
          ],
          for (final entry in groups.entries)
            if ((entry.value ?? []).isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8, children: [
                for (final item in entry.value!) Chip(label: Text(item))
              ])
            ],
          const SizedBox(height: 28),
          OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.discoverySafetyPlaceholder))),
              child: Text(l.discoveryReport)),
          TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.discoverySafetyPlaceholder))),
              child: Text(l.discoveryBlock))
        ]));
  }
}
