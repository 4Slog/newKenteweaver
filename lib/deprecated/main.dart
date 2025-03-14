import 'package:flutter/material.dart';
import 'screens/enhanced_features_screen.dart';

void main() {
  runApp(const KenteWeaverApp());
}

class KenteWeaverApp extends StatelessWidget {
  const KenteWeaverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kente Weaver',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        colorScheme: ColorScheme.dark(
          primary: Colors.indigo,
          secondary: Colors.amber,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      routes: {
        '/enhanced_features': (context) => const EnhancedFeaturesScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kente Weaver'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Kente Weaver',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/enhanced_features');
              },
              child: const Text('Explore Enhanced Features'),
            ),
          ],
        ),
      ),
    );
  }
} 