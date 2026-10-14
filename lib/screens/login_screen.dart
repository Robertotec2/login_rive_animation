import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: screenSize.width,
                height: 200,
                child: const RiveAnimation.asset(
                  'assets/login-bear-animation.riv',
                ),
              ),
              //Para separar elementos
              SizedBox(height: 10,),
              //Email
              TextField(
                decoration: InputDecoration(
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
                obscureText: _isObscure,
                decoration: InputDecoration(
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
            ],
          ),
        ),
      ),
    );
  }
}
