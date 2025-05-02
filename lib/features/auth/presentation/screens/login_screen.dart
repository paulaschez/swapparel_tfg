import 'package:chat_app/app/widgets/custom_button.dart';
import 'package:chat_app/app/widgets/custom_header.dart';
import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:chat_app/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:chat_app/features/auth/presentation/widgets/form_container.dart';
import 'package:chat_app/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:chat_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:chat_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // Controladores para los campos de texto
  final TextEditingController _userMailCtrl = TextEditingController();
  final TextEditingController _userPasswordCtrl = TextEditingController();

  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<AuthProviderC>().isLoading;
    print("DEBUG: Construyendo widget SignIn.");

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // --- Fondo Decorativo Superior ---
            GradientHeader(),
            // --- Contenido Principal ---
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.07,
                horizontal: size.width * 0.05,
              ),
              child: Column(
                children: [
                  // --- Títulos ---
                  TitleAndSubtitle(
                    title: "SignIn",
                    subtitle: "Log in to your account",
                  ),
                  SizedBox(height: size.height * 0.05), 
                  // --- Formulario ---
                  Form(
                    key: _formKey,
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: FormContainer(
                        children: [
                          // --- Campo Email ---
                          CustomTextField(
                            title: "Email",
                            icon: Icons.mail_outline,
                            controller: _userMailCtrl,
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
                          // --- Campo Contraseña ---
                          CustomTextField(
                            title: "Password",
                            icon: Icons.password,
                            controller: _userPasswordCtrl,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: size.height * 0.01),
                          // --- Enlace Olvidó Contraseña ---
                          Container(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPassword(),
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.black54, 
                                  fontSize:
                                      size.width * 0.04, 
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.05),

                          isLoading
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6380fb),
                                ),
                              )
                              :
                              // --- Botón SignIn ---
                              GestureDetector(
                                onTap: () async {
                                  // Valida el formulario
                                  if (_formKey.currentState!.validate()) {
                                    final authProvider =
                                        Provider.of<AuthProviderC>(
                                          context,
                                          listen: false,
                                        );
                                    final success = await authProvider.signIn(
                                      email: _userMailCtrl.text.trim(),
                                      password: _userPasswordCtrl.text.trim(),
                                    );

                                    if (mounted && success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Logged In Succesfully",
                                          ),
                                        ),
                                      );
                                    } else if (mounted && !success) {
                                      // Muestra el error obtenido por el provider
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.orangeAccent,
                                          content: Text(
                                            authProvider.errorMessage ??
                                                "Login failed",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: CustomButton(
                                  text: "SignIn",
                                  widthFactor: 0.33,
                                ),
                              ),
                          SizedBox(
                            height: size.height * 0.02,
                          ), 
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: size.height * 0.04,
                  ), 
                  // --- Texto y Enlace a SignUp ---
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
