import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/app/presentation/main_app_screen.dart';
import 'package:chat_app/app/widgets/custom_button.dart';
import 'package:chat_app/core/utils/responsive_utils.dart';
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
    final isLoading = context.watch<AuthProviderC>().isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.largeVerticalSpacing(context) * 3.5,
            horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
          ),
          child: Center(
            child: Column(
              children: [
                // --- Título ---
                Text(
                  "Registro",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, baseSize: 33),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context)),
                Form(
                  key: _formkey,
                  child: FormContainer(
                    children: [
                      CustomTextField(
                        title: "Nombre",
                        icon: Icons.account_circle_outlined,
                        controller: _nameCtrl,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduzca un nombre';
                          }
                          return null;
                        },
                        hintText: "Introduzca un nombre de usuario",
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
                      ),
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
                        hintText: "Introduzca su email",
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
                      ),
                      CustomTextField(
                        title: "Contraseña",
                        icon: Icons.password,
                        obscureText: true,
                        controller: _passwordCtrl,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduzca una contraseña';
                          } else if (value.length < 6) {
                            return "La contraseña debe tener al menos 6 caracteres";
                          }
                          return null;
                        },
                        hintText: "Introduzca una contraseña",
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
                      ),
                      CustomTextField(
                        title: "Confirma la contraseña",
                        icon: Icons.password,
                        obscureText: true,
                        controller: _confirmPasswordCtrl,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirme la contraseña';
                          } else if (value != _passwordCtrl.text) {
                            return "Las contraseñas no coinciden";
                          }
                          return null;
                        },
                        hintText: "Repite la contraseña",
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalSpacing(context),
                      ),
                      SwitchAuthOption(
                        txt1: "¿Ya tienes una cuenta?",
                        txt2: "Inicia sesión aquí",
                        route: SignIn(),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: ResponsiveUtils.largeVerticalSpacing(context) * 2,
                ), // Botón "SignUp"
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: () async {
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
                              SnackBar(content: Text("Registro exitoso")),
                            );

                            Navigator.pop(context);

                          } else if (mounted && !success) {
                            // Muestra el error obtenido por el provider
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.orangeAccent,
                                content: Text(
                                  authProvider.errorMessage ??
                                      "Algo falló en el registro",
                                ),
                              ),
                            );
                          }
                        }
                      },

                      child: Text(
                        "CREAR CUENTA",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(
                            context,
                            baseSize: 22,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
