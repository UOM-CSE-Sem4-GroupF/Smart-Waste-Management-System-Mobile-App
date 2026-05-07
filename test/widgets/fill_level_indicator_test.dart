import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_collect_driver/theme/app_theme.dart';
import 'package:waste_collect_driver/widgets/fill_level_indicator.dart';

void main() {
  testWidgets('FillLevelIndicator shows percent and color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FillLevelIndicator(
          fillLevel: 0.9,
          color: Colors.blue,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('90%'), findsOneWidget);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final valueColor = indicator.valueColor as AlwaysStoppedAnimation<Color?>;
    expect(valueColor.value, AppColors.accentRed);
  });
}
