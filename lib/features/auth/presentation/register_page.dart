import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/nox_theme.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) context.go('/profile/setup');
      if (next.status == AuthStatus.verificationRequired) {
        context.go('/auth/verify-email');
      }
      if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authError(next.errorCode))),
        );
      }
    });

    return AuthScaffold(
      title: l10n.authWelcome,
      mode: AuthMode.register,
      showLoginReference: true,
      onModeChanged: (mode) {
        if (mode == AuthMode.login) context.go('/auth/login');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.registerHeadline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: NoxEditorialColors.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.registerSubheadline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NoxEditorialColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          _RegisterMethod(
            icon: const _GoogleMark(),
            label: l10n.continueWithGoogle,
            loading: state.isLoading,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signInWithGoogle(),
          ),
          const SizedBox(height: 12),
          _RegisterMethod(
            icon: const Icon(Icons.apple, color: Colors.black, size: 26),
            label: l10n.continueWithApple,
            loading: state.isLoading,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signInWithApple(),
          ),
          const SizedBox(height: 12),
          _RegisterMethod(
            icon: const Icon(
              Icons.phone_iphone_rounded,
              color: Color(0xFF0756E9),
              size: 24,
            ),
            label: l10n.continueWithPhone,
            loading: false,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.phoneRegistrationSoon)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterMethod extends StatelessWidget {
  const _RegisterMethod({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 76,
        child: Material(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDFEAFB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1D274F92),
                    blurRadius: 15,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: icon),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: NoxEditorialColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: loading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0756E9),
                              size: 28,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(painter: _GoogleMarkPainter()),
      );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5;
    canvas.drawArc(rect, -.72, 1.25, false, paint..color = const Color(0xFF4285F4));
    canvas.drawArc(rect, .53, .9, false, paint..color = const Color(0xFF34A853));
    canvas.drawArc(rect, 1.43, 1.22, false, paint..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, 2.65, 1.92, false, paint..color = const Color(0xFFEA4335));
    canvas.drawLine(
      Offset(center.dx + 2, center.dy),
      Offset(size.width, center.dy),
      paint
        ..color = const Color(0xFF4285F4)
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
