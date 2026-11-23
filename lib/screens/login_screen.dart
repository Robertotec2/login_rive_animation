import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/cat_mascot.dart';
import 'products_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  bool _isLoading = false;

  // Gatito animado (reemplaza al osito de Rive, mismas entradas).
  final CatController _cat = CatController();
  MascotBool? _isChecking;
  MascotBool? _isHandsUp;
  MascotTrigger? _trigSuccess;
  MascotTrigger? _trigFail;
  MascotNumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // OWASP A07: en el Login NO se valida complejidad ni se dice qué campo falló.
  static const String _mensajeGenerico =
      'Credenciales inválidas. Verifica tu correo y contraseña.';

  @override
  void initState() {
    super.initState();
    _isChecking = _cat.isChecking;
    _isHandsUp = _cat.isHandsUp;
    _trigSuccess = _cat.trigSuccess;
    _trigFail = _cat.trigFail;
    _numLook = _cat.numLook;

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      }
    });
    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  void _mostrarErrorGlobal() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text(_mensajeGenerico)),
            ],
          ),
          backgroundColor: Color(0xFFD84315),
        ),
      );
  }

  Future<void> _onLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Solo se verifica que los campos no estén vacíos.
    if (email.isEmpty || pass.isEmpty) {
      _trigFail?.fire();
      _mostrarErrorGlobal();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _trigFail?.fire();
      _mostrarErrorGlobal();
    }
  }

  Future<void> _onForgotPassword() async {
    final resetCtrl = TextEditingController(text: emailCtrl.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_reset, color: AppColors.orange, size: 36),
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Te enviaremos un enlace para crear una nueva contraseña.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Correo electrónico',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, resetCtrl.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // No revelamos si el correo existe o no (OWASP).
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.green,
        content: Text(
          'Si el correo está registrado, recibirás un enlace para '
          'restablecer tu contraseña. Revisa también spam.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Encabezado de la tienda
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, color: AppColors.green, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Michi Market',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.greenDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Tu súper de confianza, atendido por un michi',
                  style: TextStyle(color: AppColors.orange),
                ),
                const SizedBox(height: 8),
                CatMascot(controller: _cat, height: 210),
                // Tarjeta del formulario
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '¡Hola de nuevo! 🐾',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Inicia sesión para ver el catálogo',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextField(
                        controller: emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          _isHandsUp?.change(false);
                          if (_isChecking == null) return;
                          _isChecking!.change(true);

                          final look = (value.length / 40.0 * 100.0).clamp(
                            0.0,
                            100.0,
                          );
                          _numLook?.value = look;

                          _typingDebounce?.cancel();
                          _typingDebounce = Timer(
                            const Duration(seconds: 3),
                            () {
                              if (!mounted) return;
                              _isChecking?.change(false);
                            },
                          );
                        },
                        decoration: const InputDecoration(
                          hintText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Password
                      TextField(
                        controller: passCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _isObscure,
                        onChanged: (value) {
                          _isChecking?.change(false);
                          _isHandsUp?.change(true);
                        },
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onForgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _onLogin,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.shopping_cart_outlined),
                        label: Text(_isLoading ? 'Verificando...' : 'Entrar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Aún no tienes cuenta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    emailCtrl.dispose();
    passCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}
