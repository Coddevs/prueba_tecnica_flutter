import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduling/src/providers/local_petitions.dart';
import 'package:scheduling/src/screens/home_screen.dart';
import 'package:scheduling/src/screens/petition_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  testWidgets('Check that the initial state is valid.', (tester) async {
    const homeScreen = MaterialApp(home: HomeScreen());

    // Pumping...
    await tester.pumpWidget(homeScreen);
    await tester.binding.delayed(const Duration(seconds: 2));
    await tester.pump();

    // Expect to find the item on screen.
    expect(find.byKey(const Key('empty_petitions')), findsOneWidget);
  });

  testWidgets('Check that we can type the user name.', (tester) async {
    final petitionScreen = MaterialApp(
      home: PetitionScreen(
        petition: Petition(key: const Uuid().v4()),
        onSaved: (petition) {},
      ),
    );
    const value = 'User123';

    // Pumping...
    await tester.pumpWidget(petitionScreen);

    // Expect not to find the item on screen.
    expect(find.text(value), findsNothing);

    // Interaction...
    await tester.enterText(find.byKey(const Key('user_name')), value);
    await tester.pump();

    // Expect to find the item on screen.
    expect(find.text(value), findsOneWidget);
  });

  testWidgets('Check that the button to add exists.', (tester) async {
    const homeScreen = MaterialApp(home: HomeScreen());

    // Pumping...
    await tester.pumpWidget(homeScreen);
    await tester.binding.delayed(const Duration(seconds: 2));
    await tester.pump();

    // Expect to find the item on screen.
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Navigate to PetitionScreen.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.binding.delayed(const Duration(seconds: 2));
    await tester.pump();

    // Expect to find the item on screen.
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
