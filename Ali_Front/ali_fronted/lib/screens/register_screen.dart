import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Registro exitoso. Inicia sesión.'),
      backgroundColor: Colors.green,
    ),
  );
  await Future.delayed(Duration(seconds: 2));
  Navigator.pushReplacementNamed(context, '/');
} else {
      setState(() {
        _message = "Error: \${result['message']}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.app_registration, size: 60, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Crear Cuenta',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.contains('@') ? null : 'Correo inválido',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Grado',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
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
                    TextFormField(
                      controller: _edad,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (int.tryParse(val) == null) return 'Debe ser un número válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _register,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Registrar'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _message!.startsWith("Error") ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
