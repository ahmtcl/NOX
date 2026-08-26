import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import 'profile_setup_controller.dart';

final profileCompletionProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth.user == null || auth.status != AuthStatus.authenticated)
    return false;
  try {
    return await ref
            .read(profileRepositoryProvider)
            .getProfile(auth.user!.id) !=
        null;
  } catch (_) {
    return false;
  }
});
