import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/legal_placeholder_page.dart';
import '../../features/profile/presentation/profile_setup_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/verify_email_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/splash/presentation/splash_page.dart';

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<AuthState>(authControllerProvider, (_, __) => refresh.notify());
  ref.onDispose(refresh.dispose);
  return refresh;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isProtected = location == '/profile/setup';
      if (auth.status == AuthStatus.loading ||
          location == '/' ||
          location == '/onboarding') return null;
      if (auth.status == AuthStatus.unauthenticated ||
          auth.status == AuthStatus.error)
        return isProtected ? '/auth/login' : null;
      if (auth.status == AuthStatus.verificationRequired)
        return location == '/auth/verify-email' ? null : '/auth/verify-email';
      if (auth.status == AuthStatus.authenticated && isAuthRoute)
        return '/profile/setup';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/auth', redirect: (_, __) => '/auth/login'),
      GoRoute(
          path: '/auth/login', builder: (context, state) => const LoginPage()),
      GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterPage()),
      GoRoute(
          path: '/auth/forgot-password',
          builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(
          path: '/auth/verify-email',
          builder: (context, state) => const VerifyEmailPage()),
      GoRoute(
          path: '/profile/setup',
          builder: (context, state) => const ProfileSetupPage()),
      GoRoute(
          path: '/legal/privacy',
          builder: (context, state) =>
              const LegalPlaceholderPage(isPrivacy: true)),
      GoRoute(
          path: '/legal/terms',
          builder: (context, state) =>
              const LegalPlaceholderPage(isPrivacy: false)),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
