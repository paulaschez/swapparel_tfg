import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_header.dart';
import 'package:chat_app/components/form_container.dart';
import 'package:chat_app/components/switch_auth_options.dart';
import 'package:chat_app/pages/signin.dart';
import 'package:chat_app/service/database.dart';
import 'package:chat_app/service/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/components/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_string/random_string.dart';
import 'home.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // Controladores y variables de estado
  final TextEditingController _mailCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Funcion de registro
  Future<void> registration() async {
    if (!mounted) return;

    if (_formkey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Crear usuario en Firebase Authentication
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _mailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );

        // Generar ID aleatorio y guardar los datos en Firestore
        String userId = randomAlphaNumeric(10);
        Map<String, dynamic> userInfoMap = {
          "Name": _nameCtrl.text.trim(),
          "E-mail": _mailCtrl.text.trim(),
          "username": _mailCtrl.text.trim().replaceAll("@gmail.com", ""),
          "Photo": "https://cdn-icons-png.flaticon.com/512/17246/17246491.png",
          "Id": userId,
        };
        await DatabaseMethods().addUserDetails(userInfoMap, userId);

        // Guardar datos en SharedPreferences
        await SharedPreferenceHelper().saveUserId(userId);
        await SharedPreferenceHelper().saveUserEmail(_mailCtrl.text.trim());
        await SharedPreferenceHelper().saveUserName(
          _mailCtrl.text.trim().replaceAll("@gmail.com", ""),
        );
        await SharedPreferenceHelper().saverUserDisplayName(_nameCtrl.text);
        await SharedPreferenceHelper().saverUserPic(
          "https://cdn-icons-png.flaticon.com/512/17246/17246491.png",
        );

        // Mostrar mensaje de exito y navegar a Home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Registered Succesfully",
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        if (e.code == 'weak-password') {
          errorMessage = "Password Provided is too weak";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "Account already exists";
        } else {
          errorMessage = "An error occurred: ${e.code}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(errorMessage, style: TextStyle(fontSize: 18.0)),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Encabezado con gradiente
            GradientHeader(),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.07,
                horizontal: size.width * 0.05,
              ),
              child: Column(
                children: [
                  // Título "SignUp"
                  TitleAndSubtitle(
                    title: "SignUp",
                    subtitle: "Create a new account",
                  ),
                  SizedBox(height: size.height * 0.05), // Espaciado relativo
                  // Contenedor del formulario
                  Form(
                    key: _formkey,
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: FormContainer(
                        children: [
                          CustomTextField(
                            title: "Name",
                            icon: Icons.account_circle_outlined,
                            controller: _nameCtrl,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: size.height * 0.03),
                          CustomTextField(
                            title: "Email",
                            icon: Icons.mail_outline,
                            controller: _mailCtrl,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Email';
                              } else if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return "Enter a valid E-mail";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: size.height * 0.03),
                          CustomTextField(
                            title: "Password",
                            icon: Icons.password,
                            obscureText: true,
                            controller: _passwordCtrl,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Password';
                              } else if (value.length < 6) {
                                return "The password must have at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: size.height * 0.03,
                          ), // Espaciado relativo
                          CustomTextField(
                            title: "Confirm Password",
                            icon: Icons.password,
                            obscureText: true,
                            controller: _confirmPasswordCtrl,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Confirm Password';
                              } else if (value != _passwordCtrl.text) {
                                return "The passwords don't match";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: size.height * 0.05),
                          SwitchAuthOption(
                            txt1: "Already have an account?",
                            txt2: "Sign In Now",
                            route: SignIn(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03), // Espaciado relativo
                  // Botón "SignUp"
                  _isLoading
                      ? CircularProgressIndicator(color: Color(0xFF6380fb))
                      : GestureDetector(
                        onTap: () {
                          registration();
                        },
                        child: CustomButton(text: "SignUp", widthFactor: 1),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
