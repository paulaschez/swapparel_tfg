import 'package:chat_app/components/custom_button.dart';
import 'package:chat_app/components/custom_header.dart';
import 'package:chat_app/components/form_container.dart';
import 'package:chat_app/components/switch_auth_options.dart';
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
  bool _isLoading = false;
  TextEditingController userMailCtrl = TextEditingController();

  resetPassword() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            GradientHeader(),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.07,
                horizontal: size.width * 0.05,
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
                            _isLoading
                                ? Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6380fb),
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        mail = userMailCtrl.text;
                                      });
                                    }
                                    resetPassword();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignIn(),
                                      ),
                                    );
                                  },
                                  child: CustomButton(
                                    text: "Send Email",
                                    widthFactor: 0.4,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03), // Espaciado relativo
                  SwitchAuthOption(
                    txt1: "Don't have an account?",
                    txt2: "Sign Up Now!",
                    route: SignUp(),
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
