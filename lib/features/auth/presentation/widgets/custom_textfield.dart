import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    this.validator,
    required this.hintText
  });

  final String title;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: ResponsiveUtils.fontSize(
              context,
              baseSize: 20,
            ), 
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
        TextFormField(
          
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
           
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                icon,
                color: AppColors.darkGreen,
                size: ResponsiveUtils.fontSize(
                                            context,
                                            baseSize: 25,

                                          ),
              ),
            ),
          ),
          onChanged: (value) {
            
          },
        ),
      ],
    );
  }
}
