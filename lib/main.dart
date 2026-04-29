import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/hive_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBGgUBvT9A_rKttxUpkgGctF7pnQp44EW8',
      appId: '1:124195911180:android:b86283d873e2bb4157e029',
      messagingSenderId: '124195911180',
      projectId: 'offline-first-sync-demo',
      storageBucket: 'offline-first-sync-demo.firebasestorage.app',
    ),
  );

  await HiveService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline First App',
      home: const HomeScreen(),
    );
  }
}