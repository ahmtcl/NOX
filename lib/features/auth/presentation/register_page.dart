import 'package:flutter/material.dart';

import 'login_page.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const LoginPage(initialMode: AuthMode.register);
}
