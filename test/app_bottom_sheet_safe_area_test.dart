import 'package:Glow/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final keyboard in [0.0, 300.0]) {
    testWidgets('sheet stays below notch and above keyboard $keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 34);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppSheet<void>(
                  context: context,
                  heightFactor: 1,
                  builder: (_) =>
                      const SizedBox.expand(key: ValueKey('sheet-content')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(const ValueKey('sheet-content')));
      expect(rect.top, greaterThanOrEqualTo(54));
      expect(rect.bottom, lessThanOrEqualTo(800 - keyboard));
      expect(tester.takeException(), isNull);
    });
  }
}
