import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String dominio = '@tecdesoftware.edu.mx';

  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;
  String _pass = '';

  // Reglas de contraseña (se muestran en pantalla)
  bool get _hasMinLength => _pass.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_pass);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_pass);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_pass);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_pass);
  bool get _passOk =>
      _hasMinLength && _hasUpper && _hasLower && _hasDigit && _hasSymbol;

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Correo no válido';
    }
    if (!email.endsWith(dominio)) return 'Usa tu correo institucional ($dominio)';
    return null;
  }

  String? _validatePass(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa una contraseña';
    if (!_passOk) return 'La contraseña no cumple las reglas';
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña';
    if (value != passCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _onSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim().toLowerCase(),
        password: passCtrl.text,
      );
      // Firebase inicia sesión al crear la cuenta; la cerramos para que
      // el usuario entre desde el Login.
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada correctamente. Ahora inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mensajeError(e.code)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // En el Registro sí se permiten mensajes específicos según e.code.
  String _mensajeError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo crear la cuenta ($code).';
    }
  }

  Widget _regla(bool ok, String texto) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: ok ? Colors.green : Colors.black54)),
      ],
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: _decoration('correo$dominio', Icons.email),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: _isObscure,
                  validator: _validatePass,
                  onChanged: (v) => setState(() => _pass = v),
                  decoration: _decoration(
                    'Contraseña',
                    Icons.lock,
                    suffix: IconButton(
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _regla(_hasMinLength, 'Mínimo 8 caracteres'),
                _regla(_hasUpper, 'Una letra mayúscula'),
                _regla(_hasLower, 'Una letra minúscula'),
                _regla(_hasDigit, 'Un número'),
                _regla(_hasSymbol, 'Un símbolo (!@#\$%...)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: _isObscure,
                  validator: _validateConfirm,
                  decoration: _decoration('Confirmar contraseña', Icons.lock_outline),
                ),
                const SizedBox(height: 20),
                MaterialButton(
                  minWidth: width,
                  height: 50,
                  color: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign up',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
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
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
