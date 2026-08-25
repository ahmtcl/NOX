import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/core/theme/nox_theme.dart';

void main() {
  test('NOX theme exposes brand colors', () {
    expect(NoxColors.violet.toARGB32(), 0xFF8D6BFF);
    expect(NoxTheme.dark.brightness, Brightness.dark);
  });
}
