import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_setup_draft.dart';

abstract interface class ProfileSetupDraftStore {
  Future<ProfileSetupDraft> load();
  Future<void> save(ProfileSetupDraft draft);
  Future<void> clear();
}

class SharedPreferencesProfileSetupDraftStore
    implements ProfileSetupDraftStore {
  static const _key = 'profile_setup_draft';

  @override
  Future<ProfileSetupDraft> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    if (value == null) return const ProfileSetupDraft();
    try {
      return ProfileSetupDraft.fromJson(
          jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return const ProfileSetupDraft();
    }
  }

  @override
  Future<void> save(ProfileSetupDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
