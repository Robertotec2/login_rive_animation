import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;

  StateMachineController? _controller;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? emailError;
  String? passErrror;

   // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  void _onLogin(){
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    final emailTypedError = isValidEmail(email) ? null : 'Invalid Email';
    final passTypedError = isValidPassword(pass) ? null : 'Invalid Password';

    setState(() {
      emailError = emailTypedError;
      passErrror = passTypedError;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _numLook?.value = 50.0;

    if (emailTypedError == null && passTypedError == null){
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }


  }


@override
  void initState() {

    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus){
        if (_isHandsUp != null){
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
  });
    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                //Para separar elementos
                SizedBox(height: 10,),
                //Email
                TextField(
                  controller: emailCtrl,
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    if(_isHandsUp != null){
                      _isHandsUp!.change(false);
                    }

                    if(_isChecking == null) return;
                    _isChecking!.change(true);

                    final look = (value.length / 40.0 * 100.0).clamp(
                      0.0, 
                      100.0
                    );
                    _numLook?.value = look;

                    _typingDebounce?.cancel();

                    _typingDebounce = Timer(const Duration(seconds: 3), (){
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //Para redondear los bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(height: 10,),
                //Password
                TextField(
                  controller: passCtrl,
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    if(_isChecking != null){
                      _isChecking!.change(false);
                    }

                    if(_isHandsUp == null) return;
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    errorText: passErrror,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: (){
                        //Refrescar el icono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      }, 
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      )),
                    border: OutlineInputBorder(
                      //Para redondear los bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(height: 10,),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10,),
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}
