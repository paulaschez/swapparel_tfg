import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/app/config/theme/app_theme.dart'; 
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/widgets/form_container.dart';
import 'package:swapparel/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState(); 
}

class _RegisterScreenState extends State<RegisterScreen> { 
  final TextEditingController _mailCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 

 

  @override
  void dispose() {
    _mailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);

      final success = await authProvider.signUp(
        email: _mailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
      );

      if (!mounted) return;


      if (success) {

        print("RegisterScreen: Registro exitoso, GoRouter debería redirigir.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Registro exitoso! Por favor, verifica tu correo electrónico si es necesario."),
            backgroundColor: AppColors.primaryGreen, 
          ),
        );
       
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? "Error en el registro. Inténtalo de nuevo."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingFromProvider = context.watch<AuthProviderC>().isLoading;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.largeVerticalSpacing(context) * 2.5, 
              horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
            ),
            child: Center( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text(
                    "Registro",
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, baseSize: 33),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context) * 0.8), 
                  Form(
                    key: _formKey,
                    child: FormContainer(
                      children: [
                        CustomTextField(
                          title: "Nombre",
                          icon: Icons.person_outline, 
                          controller: _nameCtrl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor introduzca su nombre'; 
                            }
                            return null;
                          },
                          hintText: "Introduzca su nombre", 
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                        CustomTextField(
                          title: "Email",
                          icon: Icons.mail_outline,
                          controller: _mailCtrl,
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
                          isPassword: true,
                          controller: _passwordCtrl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor introduzca una contraseña';
                            } else if (value.length < 6) {
                              return "La contraseña debe tener al menos 6 caracteres";
                            }
                            return null;
                          },
                          hintText: "Introduzca una contraseña (mín. 6 caracteres)",
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                        CustomTextField(
                          title: "Confirmar Contraseña", 
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmPasswordCtrl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor confirme la contraseña';
                            } else if (value != _passwordCtrl.text) {
                              return "Las contraseñas no coinciden";
                            }
                            return null;
                          },
                          hintText: "Repita la contraseña", 
                        ),
                        SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 1.5), 
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5),
                  isLoadingFromProvider
                      ? CircularProgressIndicator(color: AppColors.darkGreen)
                      : ElevatedButton(
                          onPressed: _performSignUp,
                          child: Text(
                            "CREAR CUENTA",
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, baseSize: 22),
                            ),
                          ),
                        ),
                  SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
                  SwitchAuthOption(
                    txt1: "¿Ya tienes una cuenta?",
                    txt2: "Inicia sesión aquí",
                    routePath: AppRoutes.login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}