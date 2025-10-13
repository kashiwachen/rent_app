import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_tracker/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RentTrackerApp());

    // Verify that the app launches with the home screen
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify the app title is displayed
    expect(find.text('RentTracker'), findsAtLeastNWidgets(1));

    // Verify the success message is displayed
    expect(find.text('Flutter project setup complete! ✅'), findsOneWidget);
  });
}
