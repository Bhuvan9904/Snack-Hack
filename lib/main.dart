import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/router.dart';
import 'app/theme.dart'; // ✅ Import the AppTheme
import 'core/services/modifier_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path); // <-- ✅

  // Initialize modifier service
  await ModifierService.initialize();

  runApp(const ProviderScope(child: SnackHackApp()));
}

class SnackHackApp extends StatelessWidget {
  const SnackHackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SnackHack',
      theme: AppTheme.lightTheme, // ✅ Applying custom theme here
      routerConfig:
          appRouter, // <-- Use the actual router config object, not a string
    );
  }
}
