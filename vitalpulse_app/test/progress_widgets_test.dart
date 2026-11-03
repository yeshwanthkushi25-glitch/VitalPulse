import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalpulse/widgets/progress_widgets.dart';

void main() {
  testWidgets('macro progress bar shows values and progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroProgressBar(
            label: 'Protein',
            current: 65,
            target: 130,
            unit: 'g',
          ),
        ),
      ),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('65 / 130 g'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.5);
  });

  testWidgets('wellness score card shows score and streak', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WellnessScoreCard(score: 84, streak: 4)),
      ),
    );

    expect(find.text('84'), findsOneWidget);
    expect(find.text('4-day consistency streak'), findsOneWidget);
    expect(find.text('Daily wellness score'), findsOneWidget);
  });
}
