import 'package:chat_app/app/widgets/custom_button.dart';
import 'package:chat_app/app/widgets/custom_header.dart';
import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:chat_app/features/auth/presentation/widgets/form_container.dart';
import 'package:chat_app/features/auth/presentation/widgets/switch_auth_options.dart';
import 'package:chat_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/features/auth/presentation/widgets/custom_textfield.dart';
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
                            isLoading
                                ? Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6380fb),
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final authProvider =
                                          Provider.of<AuthProviderC>(
                                            context,
                                            listen: false,
                                          );
                                      final success = await authProvider
                                          .resetPassword(
                                            email: userMailCtrl.text.trim(),
                                          );

                                      if (mounted && success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Email sent Succesfully",
                                            ),
                                          ),
                                        );
                                      } else if (mounted && !success) {
                                        // Muestra el error obtenido por el provider
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                Colors.orangeAccent,
                                            content: Text(
                                              authProvider.errorMessage ??
                                                  "Something failed",
                                            ),
                                          ),
                                        );
                                      }
                                    }
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
