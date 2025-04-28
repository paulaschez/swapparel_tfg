import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_header.dart';
import 'package:chat_app/components/form_container.dart';
import 'package:chat_app/pages/signin.dart';
import 'package:chat_app/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/components/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String mail = "";

  final _formKey = GlobalKey<FormState>();
  TextEditingController userMailCtrl = new TextEditingController();

  resetPassword() async {
    if (!mounted) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password Reset Email has been sent",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No User found for that email.",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            GradientHeader(),
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.07,
              ), // Margen superior relativo
              child: Column(
                children: [
                  TitleAndSubtitle(
                    title: "Password Recovery",
                    subtitle: "Enter your mail",
                  ),
                  SizedBox(height: size.height * 0.05), // Espaciado relativo
                  // Contenedor del formulario
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(10),
                        child: FormContainer(
                          children: [
                            CustomTextField(
                              title: "Email",
                              icon: Icons.mail_outline,
                              controller: userMailCtrl,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter Email';
                                } else if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  // Validación de email más robusta
                                  return "Enter a valid E-mail";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: size.height * 0.05),
                            GestureDetector(
                              onTap: () {
                                if(_formKey.currentState!.validate()){
                                  setState((){
                                    mail = userMailCtrl.text;
                                  });
                                }
                                resetPassword();
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> SignIn()));
                              },
                              child: CustomButton(
                                text: "Send Email",
                                widthFactor: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03), // Espaciado relativo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: Colors.black87, // Color más suave
                          fontSize: size.width * 0.04, // Tamaño relativo
                        ),
                      ),
                      // Añadir GestureDetector si quieres que sea clickeable para ir a SignUp
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SignUp()),
                          );
                        },
                        child: Text(
                          " Sign Up Now!",
                          style: TextStyle(
                            color: Color(0xFF7f30fe),
                            fontSize: size.width * 0.04, // Tamaño relativo
                            fontWeight: FontWeight.bold, // Más destacado
                          ),
                        ),
                      ),
                    ],
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
