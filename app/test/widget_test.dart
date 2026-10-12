import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/main.dart';
import 'package:mushaf/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch asks for a riwaya before starting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await Settings.load();
    await tester.pumpWidget(MushafApp(state: AppState(settings)));
    await tester.pump();

    final start = find.byKey(const ValueKey('start'));
    expect(tester.widget<FilledButton>(start).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('riwaya-warsh')));
    await tester.pump();
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);

    await tester.tap(start);
    await tester.pump();
    expect(settings.onboarded, isTrue);
    expect(settings.riwaya.name, 'warsh');
  });
}
