import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final ApiService apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _password = TextEditingController();

  final List<String> gradosDisponibles = ['9', '10', '11'];
  String? _gradoSeleccionado;

  bool _isLoading = false;
  String? _message;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await apiService.register({
      "username": _username.text.trim(),
      "nombre": _nombre.text.trim(),
      "email": _email.text.trim(),
      "grado": _gradoSeleccionado,
      "edad": int.tryParse(_edad.text.trim()) ?? 0,
      "password": _password.text.trim(),
    });

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      if (!mounted) return;
      _animationController.forward();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FadeTransition(
          opacity: _fadeAnimation,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Text('🎉 ¡Registro Exitoso!', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Tu cuenta fue creada correctamente. Ahora puedes iniciar sesión.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _message = "Error: ${result['message']}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: Container(
            width: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipPath(
                  clipper: TopWaveClipper(),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2F), Color(0xFF8DB9E4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Registro ALI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo Usuario
                        TextFormField(
                          controller: _username,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Nombre completo (validación de nombre completo)
                        TextFormField(
                          controller: _nombre,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: const Icon(Icons.badge),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Requerido';
                            }
                            final partes = val.trim().split(' ');
                            // Debe tener al menos dos palabras y cada palabra mínimo 2 caracteres
                            if (partes.length < 2 ||
                                partes.any((p) => p.trim().length < 2)) {
                              return 'Ingrese nombre completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Correo electrónico (con validación mínima)
                        TextFormField(
                          controller: _email,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Requerido';
                            }
                            final email = val.trim();
                            if (!email.contains('@')) {
                              return 'Correo inválido';
                            }
                            if (!email.toLowerCase().endsWith('@gmail.com')) {
                              return 'Solo se aceptan correos @gmail.com';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Grado
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Grado',
                            prefixIcon: const Icon(Icons.school),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          value: _gradoSeleccionado,
                          items: gradosDisponibles.map((grado) {
                            return DropdownMenuItem(
                              value: grado,
                              child: Text('Grado $grado'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _gradoSeleccionado = value;
                            });
                          },
                          validator: (val) => val == null ? 'Seleccione un grado' : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Edad
                        TextFormField(
                          controller: _edad,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Edad',
                            prefixIcon: const Icon(Icons.cake),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            if (int.tryParse(val.trim()) == null) return 'Debe ser un número válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          onFieldSubmitted: (_) => _register(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Requerido';
                            }
                            if (val.trim().length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botón Registrar
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _register,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Registrar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8DB9E4),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),

                        // Mensaje de resultado
                        if (_message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _message!.startsWith("Error") ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
