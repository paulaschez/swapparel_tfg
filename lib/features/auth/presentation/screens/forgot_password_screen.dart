import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/auth/presentation/widgets/form_container.dart';
import 'package:swapparel/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController userMailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<AuthProviderC>().isLoading;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.largeVerticalSpacing(context) * 3.5,
            horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
          ), // Margen superior relativo
          child: Column(
            children: [
              Text(
                "Recuperar Contraseña",
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, baseSize: 33),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
              ),
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
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
                        hintText: "Introduzca su email",
                      ),

                      SizedBox(height: size.height * 0.05),
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.darkGreen,
                            ),
                          )
                          : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final authProvider = Provider.of<AuthProviderC>(
                                  context,
                                  listen: false,
                                );
                                final success = await authProvider
                                    .resetPassword(
                                      email: userMailCtrl.text.trim(),
                                    );

                                if (mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Correo enviado con éxito"),
                                    ),
                                  );
                                } else if (mounted && !success) {
                                  // Muestra el error obtenido por el provider
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.orangeAccent,
                                      content: Text(
                                        authProvider.errorMessage ??
                                            "Algo falló",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child:Text(
                                  "Enviar Correo",
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

              SizedBox(
                height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
              ),
              SwitchAuthOption(
                txt1: "¿No tienes cuenta?",
                txt2: "Registrate aquí",
                routePath: AppRoutes.register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
