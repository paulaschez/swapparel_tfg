import 'package:swapparel/app/config/theme/app_theme.dart';
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

class FormContainer extends StatelessWidget {
  const FormContainer({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(10),
        color: AppColors.lightGreen,
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveUtils.largeVerticalSpacing(context) * 2,
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }
}
