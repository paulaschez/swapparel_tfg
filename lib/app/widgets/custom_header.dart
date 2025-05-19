import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return
    // Gradiente de fondo
    Container(
      height: size.height * 0.25,
      width: size.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen,AppColors.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(size.width, size.height * 0.1),
        ),
      ),
    );
  }
}

class TitleAndSubtitle extends StatelessWidget {
  const TitleAndSubtitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Título "SignUp"
        Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.07, // Tamaño de fuente relativo
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            subtitle,
            style: TextStyle(
              color: Color(0xFFbbb0ff),
              fontSize: size.width * 0.05, // Tamaño de fuente relativo
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
