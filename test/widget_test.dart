import 'package:flutter_test/flutter_test.dart';
import 'package:scale_a_day/main.dart';

void main() {
  testWidgets('shows the scale trainer and main synth controls', (
    tester,
  ) async {
    await tester.pumpWidget(const ScaleADayApp());
    await tester.pump();

    expect(find.text('MAGNESIUM'), findsOneWidget);
    expect(find.text('MIDI INPUT'), findsOneWidget);
    expect(find.text('SCAN / CONNECT'), findsOneWidget);
    expect(find.text('SCALE EXPLORER'), findsOneWidget);
    expect(
      find.text(
        'POLYSYNTH DIATONIC CHORDS   ·   Hold a pad to audition harmony',
      ),
      findsOneWidget,
    );
    expect(find.text('PANIC / SILENCE'), findsOneWidget);
    expect(find.text('START DRILL'), findsOneWidget);
  });

  testWidgets('loads the Tobacco patch settings', (tester) async {
    await tester.pumpWidget(const ScaleADayApp());
    await tester.pump();

    await tester.ensureVisible(find.text('Tobacco'));
    await tester.tap(find.text('Tobacco'));
    await tester.pump();

    expect(find.text('350 ms'), findsOneWidget);
    expect(find.text('97%'), findsOneWidget);
    expect(find.text('50 ct'), findsOneWidget);
    expect(find.text('9719 Hz'), findsOneWidget);
    expect(find.text('13.8 Q'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('0.35s'), findsOneWidget);
    expect(find.text('1.07s'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1.48s'), findsOneWidget);
  });
}
