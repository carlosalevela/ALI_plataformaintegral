import 'package:flutter/material.dart';
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
  final TextEditingController _grado = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _password = TextEditingController();

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
      "grado": _grado.text.trim(),
      "edad": int.tryParse(_edad.text.trim()) ?? 0,
      "password": _password.text.trim(),
    });

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _message = "Registro exitoso. Ahora puedes iniciar sesión.";
      });
    } else {
      setState(() {
        _message = "Error: ${result['message']}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Usuario'), validator: (val) => val!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre completo'), validator: (val) => val!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Correo electrónico'), validator: (val) => val!.contains('@') ? null : 'Correo inválido'),
              TextFormField(controller: _grado, decoration: const InputDecoration(labelText: 'Grado'), validator: (val) => val!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _edad, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _password, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true, validator: (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Registrar'),
                    ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _message!,
                    style: TextStyle(color: _message!.startsWith("Error") ? Colors.red : Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
