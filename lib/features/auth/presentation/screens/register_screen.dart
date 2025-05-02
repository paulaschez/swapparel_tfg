import 'package:chat_app/app/widgets/custom_button.dart';
import 'package:chat_app/app/widgets/custom_header.dart';
import 'package:chat_app/features/auth/presentation/widgets/form_container.dart';
import 'package:chat_app/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:chat_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<AuthProviderC>().isLoading;

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
                  SizedBox(height: size.height * 0.03), 
                  // Botón "SignUp"
                  isLoading
                      ? CircularProgressIndicator(color: Color(0xFF6380fb))
                      : GestureDetector(
                        onTap: () async {
                          if (_formkey.currentState!.validate()) {
                            final authProvider = Provider.of<AuthProviderC>(
                              context,
                              listen: false,
                            );
                            final success = await authProvider.signUp(
                              email: _mailCtrl.text.trim(),
                              password: _passwordCtrl.text.trim(),
                              username: _nameCtrl.text.trim(),
                            );

                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Registered Succesfully"),
                                ),
                              );
                            } else if (mounted && !success) {
                              // Muestra el error obtenido por el provider
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.orangeAccent,
                                  content: Text(
                                    authProvider.errorMessage ??
                                        "Registration failed",
                                  ),
                                ),
                              );
                            }
                          }
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
