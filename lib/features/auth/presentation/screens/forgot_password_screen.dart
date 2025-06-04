import 'package:go_router/go_router.dart';
import 'package:swapparel/app/config/routes/app_routes.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:swapparel/features/auth/presentation/provider/auth_provider.dart';
import 'package:swapparel/features/auth/presentation/widgets/form_container.dart';
import 'package:swapparel/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:flutter/material.dart';
import 'package:swapparel/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget { 
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userMailCtrl = TextEditingController(); 


  @override
  void dispose() {
    _userMailCtrl.dispose();
    super.dispose();
  }

  Future<void> _performPasswordReset() async {
    if (_formKey.currentState!.validate()) {
      // Opcional: setState(() => _isButtonLoading = true);
      final authProvider = Provider.of<AuthProviderC>(context, listen: false);

      final success = await authProvider.resetPassword(
        email: _userMailCtrl.text, // .trim() ya se hace en el provider
      );

      if (!mounted) return;

      // Opcional: setState(() => _isButtonLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Si el correo está registrado, recibirás un enlace para restablecer tu contraseña."),
            backgroundColor: AppColors.primaryGreen, // Un color de éxito/informativo
          ),
        );
       
        if (mounted) context.go(AppRoutes.login);
      
        _userMailCtrl.clear(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? "Error al enviar el correo. Inténtalo de nuevo."),
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
      appBar: AppBar( 
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.largeVerticalSpacing(context) * 1.5,
              horizontal: ResponsiveUtils.horizontalPadding(context) * 1.5,
            ),
            child: Column(
              children: [
                Text(
                  "Recuperar Contraseña",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, baseSize: 30), 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                Text( // Texto instructivo
                  "Introduce tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, baseSize: 15),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context) * 1.2),
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
                        hintText: "Introduzca su email registrado", 
                      ),
                      SizedBox(height: size.height * 0.05),
                      isLoadingFromProvider
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.darkGreen,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _performPasswordReset, 
                              child: Text(
                                "ENVIAR CORREO", 
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(context, baseSize: 20), 
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveUtils.largeVerticalSpacing(context) * 1.5),
                SwitchAuthOption(
                  txt1: "¿Recuerdas tu contraseña?", 
                  txt2: "Inicia sesión aquí",
                  routePath: AppRoutes.login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}