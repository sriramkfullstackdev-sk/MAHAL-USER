import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mahal_user/main.dart';
import 'package:mahal_user/models/mahal_model.dart';
import 'package:mahal_user/screens/home/home_page.dart';
import 'package:mahal_user/screens/home/widgets/mahal_card.dart';
import 'package:mahal_user/screens/profile/booking_history_page.dart';

void main() {
  testWidgets('shows the user OTP page when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        navigatorKey: GlobalKey<NavigatorState>(),
        hasSession: false,
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('home page includes a consistent app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('mahal card shows the actual image when base64 data is available', (WidgetTester tester) async {
    const base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAF';
    await tester.pumpWidget(
      MaterialApp(
        home: MahalCard(
          mahal: MahalModel(
            id: '1',
            mahalName: 'Royal Palace',
            price: '5000',
            location: 'Chennai',
            imageBase64: base64Image,
          ),
        ),
      ),
    );

    expect(find.text('MAHAL\nPHOTOS'), findsNothing);
    expect(find.byType(MahalCard), findsOneWidget);
  });

  test('parses mahal details from backend response fields used by the user app', () {
    final mahal = MahalModel.fromJson({
      'mahal_id': 'abc123',
      'mahal_name': 'Royal Palace',
      'full_day_price': 4500,
      'city': 'Chennai',
      'mahal_images': 'aaa,bbb,ccc',
    });

    expect(mahal.id, 'abc123');
    expect(mahal.mahalName, 'Royal Palace');
    expect(mahal.price, '4500');
    expect(mahal.location, 'Chennai');
    expect(mahal.imageBase64, 'aaa,bbb,ccc');
  });

  test('formats booking and event dates to dd/MM/yy', () {
    expect(formatDateForDisplay('2026-08-14'), '14/08/26');
    expect(formatDateForDisplay('2026-07-01'), '01/07/26');
    expect(formatDateForDisplay(''), 'Not available');
  });
}
