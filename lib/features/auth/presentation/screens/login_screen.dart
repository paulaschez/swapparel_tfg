import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:swapparel/features/auth/presentation/widgets/form_container.dart';
import 'package:swapparel/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userMailCtrl = TextEditingController();
  final TextEditingController _userPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _userMailCtrl.dispose();
    _userPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);

      final success = await authProvider.signIn(
        email: _userMailCtrl.text, 
        password: _userPasswordCtrl.text,
      );

      if (!mounted) return; 

      if (success) {

        print("LoginScreen: Inicio de sesión exitoso, GoRouter debería redirigir.");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("¡Bienvenido/a de nuevo!"),
             backgroundColor: AppColors.primaryGreen, 
           ),
         );
      } else {
        // Mostrar el error obtenido del provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? "Error al iniciar sesión. Inténtalo de nuevo."),
            backgroundColor: AppColors.error, 
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoadingFromProvider = context.watch<AuthProviderC>().isLoading;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.largeVerticalSpacing(context) * 3.5,
              horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
            ),
            child: Column(
              children: [
                Text(
                  "Iniciar Sesión",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, baseSize: 33),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context)),
                Form(
                  key: _formKey,
                  child: FormContainer(
                    children: [
                      CustomTextField(
                        title: "Email",
                        icon: Icons.mail_outline,
                        controller: _userMailCtrl,
                        keyboardType: TextInputType.emailAddress, 
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduzca su email';
                          }
                          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegex.hasMatch(value)) {
                            return "Introduzca un email válido";
                          }
                          return null;
                        },
                        hintText: "Introduzca su email",
                      ),
                      SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                      CustomTextField(
                        title: "Contraseña",
                        icon: Icons.lock_outline, 
                        controller: _userPasswordCtrl,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduzca la contraseña';
                          }
                           if (value.length < 6) {
                             return 'La contraseña debe tener al menos 6 caracteres.';
                           }
                          return null;
                        },
                        hintText: "Introduzca su contraseña",
                      ),
                      SizedBox(height: size.height * 0.01),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push(AppRoutes.forgotPassword);
                          },
                          child: Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: ResponsiveUtils.fontSize(context, baseSize: 15),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.05),
                      Center(
                        child: isLoadingFromProvider 
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.darkGreen,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _performLogin, 
                                child: Text(
                                  "INICIAR SESIÓN",
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.fontSize(context, baseSize: 22),
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                SwitchAuthOption(
                  txt1: "¿No tienes cuenta?",
                  txt2: "Regístrate aquí", 
                  routePath: AppRoutes.register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}