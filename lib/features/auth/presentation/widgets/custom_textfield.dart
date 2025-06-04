import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.icon,
    this.isPassword = false, 
    required this.controller,
    this.validator,
    required this.hintText,
    this.keyboardType = TextInputType.text, // Para otros tipos de input
  });

  final String title;
  final IconData icon;
  final bool isPassword; 
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final TextInputType keyboardType;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureTextState;

  @override
  void initState() {
    super.initState();
    _obscureTextState = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: Colors.black,
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 18,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureTextState, 
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: InputBorder.none, 
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                widget.icon,
                color: AppColors.darkGreen,
                size: ResponsiveUtils.fontSize(
                  context,
                  baseSize: 25,
                ),
              ),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      // Cambiar el icono basado en el estado de _obscureTextState
                      _obscureTextState
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.darkGreen.withValues(alpha:0.7),
                    ),
                    onPressed: () {
                
                      setState(() {
                        _obscureTextState = !_obscureTextState;
                      });
                    },
                  )
                : null, 
          ),

        ),
      ],
    );
  }
}