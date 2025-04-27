import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    this.validator
  });

  final String title;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Obtener el tamaño de la pantalla

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: size.width * 0.045, // Tamaño de fuente relativo al ancho
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: size.height * 0.01), // Espaciado vertical relativo
        Container(
          padding: EdgeInsets.only(left: size.width * 0.02), // Padding relativo
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.0,
              color: Colors.black38,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                icon,
                color: Color(0xFF7f30fe),
                size: size.width * 0.06, // Tamaño del ícono relativo
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: size.height * 0.02, // Padding interno relativo
              ),
            ),
          ),
        ),
      ],
    );
  }
}