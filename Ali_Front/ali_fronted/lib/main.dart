import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';     // ← para initializeDateFormatting

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/estudiante_home.dart';
import 'screens/test_grado9_screen.dart';
import 'screens/test_grado_10_11_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga datos de localización para español.
  // Si más adelante usas otros idiomas, repite con su código
  // o llama a initializeDateFormatting() sin argumentos.
  await initializeDateFormatting('es', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALI PSICOORIENTADORA',

      // ─── Localización ───────────────────────────────────────────
      locale: const Locale('es'),            // idioma por defecto
      supportedLocales: const [
        Locale('es'),                         // español
        Locale('en'),                         // inglés (opcional)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ─── Tema ──────────────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // ─── Rutas de la app ───────────────────────────────────────
      initialRoute: '/',
      routes: {
        '/':                 (context) => const LoginScreen(),
        '/register':         (context) => const RegisterScreen(),
        '/admin':            (context) => const AdminDashboard(),
        '/estudiante':       (context) => const EstudianteHome(),
        '/test_grado9':      (context) => TestGrado9Page(),
        '/test_grado_10_11': (context) => TestGrado1011Screen(),
      },
    );
  }
}
