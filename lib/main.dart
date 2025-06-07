import 'package:artefacto/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'model/visit_note_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VisitNoteAdapter());

  // Delete existing box if exists
  if (await Hive.boxExists('visit_notes')) {
    await Hive.deleteBoxFromDisk('visit_notes');
  }

  // Open box with new schema
  await Hive.openBox<VisitNote>('visit_notes');

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menghilangkan tulisan debug
      title: 'Artefacto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFF61313),
        ),
        useMaterial3: true, // kalau pakai Material 3
      ),
      home: const Splashscreen(), // Halaman pertama
    );
  }
}
