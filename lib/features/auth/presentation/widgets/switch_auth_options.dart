
import 'package:swapparel/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SwitchAuthOption extends StatelessWidget {
  const SwitchAuthOption({
    super.key,
    required this.txt1,
    required this.txt2,
    required this.routePath,
    this.replace = true,
  });

  final String txt1;
  final String txt2;
  final String routePath;
  final bool replace;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            txt1,
            style: TextStyle(
              color: Colors.black,
              fontSize: ResponsiveUtils.fontSize(context, baseSize: 14),
            ),
          ),

          TextButton(
            onPressed: () {
              replace? context.go(routePath) : context.push(routePath);
            },
            child: Text(
              txt2,
              style: TextStyle(
                color: Colors.black,
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
