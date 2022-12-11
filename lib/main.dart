import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheduling/src/providers/local_petitions.dart';
import 'package:scheduling/src/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localPetitions = LocalPetitions();
  await localPetitions.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: localPetitions)],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scheduling',
      theme: ThemeData.dark(),
      home: HomeScreen(provider: context.read<LocalPetitions>()),
      debugShowCheckedModeBanner: false,
    );
  }
}
