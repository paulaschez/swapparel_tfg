
import 'package:chat_app/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

class SwitchAuthOption extends StatelessWidget {
  const SwitchAuthOption({
    super.key,
    required this.txt1,
    required this.txt2,
    required this.route,
  });

  final String txt1;
  final String txt2;
  final Widget route;

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
              fontSize: ResponsiveUtils.fontSize(context, baseSize: 16),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => route),
              );
            },
            child: Text(
              txt2,
              style: TextStyle(
                color: Colors.black,
                fontSize: ResponsiveUtils.fontSize(context, baseSize: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
