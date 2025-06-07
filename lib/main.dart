import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'model/visit_note_model.dart';
import 'package:artefacto/pages/splash_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:artefacto/service/user_provider_service.dart';

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
    return ChangeNotifierProvider(
      create: (context) => UserProviderService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Artefacto',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff233743)),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
