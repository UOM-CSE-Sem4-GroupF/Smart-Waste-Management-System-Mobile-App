import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_collect_driver/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip renders label and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusChip(
          label: 'Zone 1',
          icon: Icons.location_on_rounded,
          color: Colors.blue,
        ),
      ),
    );

    expect(find.text('Zone 1'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
  });
}
