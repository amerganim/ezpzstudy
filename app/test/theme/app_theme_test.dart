import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/theme/app_theme.dart';

void main() {
  // Regression test: AppTheme.light() once scaled the whole text theme with
  // fontSizeFactor, which trips a debug assertion for any Material 3 text style
  // that has a null fontSize. This renders text under the real theme so that
  // class of crash is caught in CI, not only on a device.
  testWidgets('AppTheme renders default text styles without asserting',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              Text('Body'),
              Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('scaling preserves styles whose fontSize is null (no assertion)', () {
    // The bug was scaling a null-fontSize style. The theme must build without
    // throwing regardless of which base styles carry an explicit size.
    expect(() => AppTheme.light().textTheme, returnsNormally);
  });
}
