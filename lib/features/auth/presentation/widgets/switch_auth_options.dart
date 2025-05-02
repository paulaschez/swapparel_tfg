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
    final size = MediaQuery.of(context).size;
    return Center(
      child: Wrap(
        spacing: size.width*0.01,
        alignment: WrapAlignment.center,
        children: [
          Text(
            txt1,
            style: TextStyle(
              color: Colors.black,
              fontSize: size.width * 0.04,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => route,
                ),
              );
            },
            child: Text(
              txt2,
              style: TextStyle(
                color: Color(0xFF7f30fe),
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}