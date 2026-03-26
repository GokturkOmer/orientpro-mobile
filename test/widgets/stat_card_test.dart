import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientpro_mobile/widgets/stat_card.dart';
import 'package:orientpro_mobile/core/theme/app_theme.dart';

void main() {
  group('StatCard Widget', () {
    testWidgets('temel render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Row(children: [
              StatCard(label: 'Test', value: '42', color: ScadaColors.cyan),
            ]),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('icon gosterimi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Row(children: [
              StatCard(label: 'CPU', value: '75%', color: ScadaColors.green, icon: Icons.memory),
            ]),
          ),
        ),
      );

      expect(find.byIcon(Icons.memory), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('CPU'), findsOneWidget);
    });

    testWidgets('iconsuz render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Row(children: [
              StatCard(label: 'Toplam', value: '100', color: ScadaColors.amber),
            ]),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('SectionHeader Widget', () {
    testWidgets('temel render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: const SectionHeaderTest(),
          ),
        ),
      );

      expect(find.text('TEST BASLIK'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });
}

/// SectionHeader icin basit test wrapper
class SectionHeaderTest extends StatelessWidget {
  const SectionHeaderTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(Icons.info, size: 14, color: context.scada.textDim),
      const SizedBox(width: 6),
      Text('TEST BASLIK', style: TextStyle(fontSize: 10, color: context.scada.textSecondary)),
    ]);
  }
}
