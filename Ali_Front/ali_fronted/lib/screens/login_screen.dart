import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final ApiService apiService = ApiService();

  bool _isLoading = false;
  String? _error;

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await apiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final rol = result['role'];
      if (rol == 'admin') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/estudiante');
      }
    } else {
      setState(() => _error = result['message']);
    }
  }

  // ======= NUEVO: flujo "¿Olvidaste tu contraseña?" =======
  void _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Correo registrado'),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty) return;

                        setState(() => sending = true);
                        final resp = await apiService.solicitarRecuperacion(email);
                        if (ctx.mounted) Navigator.pop(ctx, resp);
                      },
                child: sending
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar enlace'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    final ok = result['success'] == true;
    final msg = (result['detail'] ?? result['message'] ?? (ok
        ? 'Si el correo existe, te enviamos un enlace.'
        : 'No se pudo enviar el enlace.')) as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final wrapperWidth = isWide ? 980.0 : 420.0;

            final content = isWide
                ? Row(
                    children: const [
                      // --------- PANEL ILUSTRADO IZQUIERDO ---------
                      Expanded(child: _IllustrationCard()),
                      SizedBox(width: 24),
                      // --------- FORMULARIO ---------
                      Expanded(child: _LoginCardWrapper()),
                    ],
                  )
                : const _LoginCardWrapper();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: wrapperWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper que inyecta tus controladores/estado al card
/// y aplica micro-animación de entrada (fade + slide).
class _LoginCardWrapper extends StatelessWidget {
  const _LoginCardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>()!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 22), // baja -> arriba
        child: Opacity(opacity: t, child: child),
      ),
      child: _LoginCard(
        usernameController: state._usernameController,
        emailController: state._emailController,
        passwordController: state._passwordController,
        isLoading: state._isLoading,
        error: state._error,
        onLogin: state._login,
        onForgot: state._forgotPassword, // <-- NUEVO
      ),
    );
  }
}

/// ================== TARJETA DEL FORMULARIO (derecha / móvil) ==================
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.error,
    required this.onLogin,
    required this.onForgot, // <-- NUEVO
  });

  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback onForgot; // <-- NUEVO

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo ALI arriba
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/logo_ali.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_outlined,
                  color: Colors.blue.shade300,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ALI ORIENTADOR VOCACIONAL',
            style: TextStyle(
              color: const Color(0xFF1C274C),
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenido de nuevo',
            style: TextStyle(color: Colors.black.withOpacity(.55)),
          ),
          const SizedBox(height: 22),

          _Input(
            controller: emailController,
            hint: 'Email',
            icon: Icons.alternate_email,
            onSubmit: onLogin,
          ),
          const SizedBox(height: 14),

          // === Password con botón mostrar/ocultar ===
          _PasswordInput(
            controller: passwordController,
            hint: 'Contraseña',
            onSubmit: onLogin,
          ),
          const SizedBox(height: 14),

          // Campo extra requerido por tu lógica (se mantiene)
          _Input(
            controller: usernameController,
            hint: 'Usuario',
            icon: Icons.person_outline,
            onSubmit: onLogin,
          ),

          // === “¿Olvidaste tu contraseña?” debajo de Usuario ===
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot, // <-- conectado
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF376AED), Color(0xFF2F55D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Iniciar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/register'),
            child: const Text(
              'Registrarse',
              style: TextStyle(
                color: Color(0xFF2F55D4),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],

          const SizedBox(height: 8),
          Opacity(
            opacity: .6,
            child: Text(
              '© 2025 ALI',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

  /// ================== PANEL ILUSTRADO IZQUIERDO (centrado + burbujas) ==================
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Burbujas suaves
          const Positioned(
            top: 40, left: -30,
            child: _Blob(size: 140, c1: Color(0xFFBFD7FF), c2: Color(0xFFE6F0FF)),
          ),
          const Positioned(
            bottom: 60, right: -20,
            child: _Blob(size: 160, c1: Color(0xFFD9E7FF), c2: Color(0xFFF2F7FF)),
          ),
          // Imagen centrada
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FractionallySizedBox(
                widthFactor: 0.86,
                child: Image.asset(
                  'assets/orientacion_vocacional.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.c1, required this.c2});
  final double size;
  final Color c1, c2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c1, c2]),
        boxShadow: [BoxShadow(color: c1.withOpacity(.35), blurRadius: 24, spreadRadius: 6)],
      ),
    );
  }
}

/// ================== INPUTS ==================
class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade400),
        filled: true,
        fillColor: const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2F55D4), width: 1.6),
        ),
      ),
    );
  }
}

// Password con toggle (UI)
class _PasswordInput extends StatefulWidget {
  const _PasswordInput({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onSubmitted: (_) => widget.onSubmit(),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey.shade400),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2F55D4), width: 1.6),
        ),
      ),
    );
  }
}

final _cardDeco = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ],
);
