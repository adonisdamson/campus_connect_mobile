import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_connect_mobile/core/widgets.dart';
import 'package:campus_connect_mobile/core/payment_picker.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CCButton', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(_wrap(const CCButton('Request ride')));
      expect(find.text('Request ride'), findsOneWidget);
    });

    testWidgets('fires onTap when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(CCButton('Go', onTap: () => tapped = true)));
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('hides the label and ignores taps while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(CCButton('Pay', loading: true, onTap: () => tapped = true)));
      expect(find.text('Pay'), findsNothing); // spinner instead of label
      await tester.tap(find.byType(CCButton));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('CCEmpty', () {
    testWidgets('shows title and subtitle with an icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const CCEmpty(icon: Icons.inbox, title: 'Nothing here', subtitle: 'Come back later'),
      ));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Come back later'), findsOneWidget);
    });

    testWidgets('builds with a branded illustration without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const CCEmpty(illustration: 'empty_box', title: 'Cart is empty', subtitle: 'Add items'),
      ));
      expect(find.text('Cart is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('payMethodFor', () {
    test('maps known codes to labels', () {
      expect(payMethodFor('WALLET').label, 'Campus Wallet');
      expect(payMethodFor('MTN_MOMO').label, 'MTN MoMo');
    });

    test('falls back to Cash for unknown codes', () {
      expect(payMethodFor('NONSENSE').code, 'CASH');
    });
  });
}
