import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/core/utils/responsive_utils.dart';
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.largeVerticalSpacing(context) * 3.5,
            horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
          ),
          child: Column(
            children: [
              // --- Título ---
              Text(
                "Iniciar Sesión",
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, baseSize: 33),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context)),
              // --- Formulario ---
              Form(
                key: _formKey,
                child: FormContainer(
                  children: [
                    // --- Campo Email ---
                    CustomTextField(
                      title: "Email",
                      icon: Icons.mail_outline,
                      controller: _userMailCtrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor introduzca su email';
                        } else if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return "Introduzca un email válido";
                        }
                        return null;
                      },
                      hintText: "Introduzca su email",
                    ),
                    SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                    // --- Campo Contraseña ---
                    CustomTextField(
                      title: "Contraseña",
                      icon: Icons.password,
                      controller: _userPasswordCtrl,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor introduzca la contraseña';
                        }
                        return null;
                      },
                      hintText: "Introduzca su contraseña",
                    ),
                    SizedBox(height: size.height * 0.01),
                    // --- Enlace Olvidó Contraseña ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPassword(),
                            ),
                          );
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: ResponsiveUtils.fontSize(
                              context,
                              baseSize: 15,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),

                    Center(
                      child:
                          isLoading
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.darkGreen,
                                ),
                              )
                              :
                              // --- Botón SignIn ---
                              ElevatedButton(
                                onPressed: () async {
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
                                child: Text(
                                  "INICIAR SESIÓN",
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.fontSize(
                                      context,
                                      baseSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                    ),

                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.04),
              // --- Texto y Enlace a SignUp ---
              SwitchAuthOption(
                txt1: "¿No tienes cuenta?",
                txt2: "Registrate aquí",
                route: SignUp(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
