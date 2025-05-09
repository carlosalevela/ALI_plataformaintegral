import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/estudiante_home.dart';
import 'screens/test_grado9_screen.dart'; // ✅ Importación añadida

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALI PSICOOREINTADORA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/estudiante': (context) => const EstudianteHome(),
        '/test_grado9': (context) => TestGrado9Page(), // ✅ Ruta añadida
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
