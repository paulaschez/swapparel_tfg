import 'package:flutter/material.dart';
class IncomingMessage extends StatelessWidget {
  const IncomingMessage({super.key, required this.size, required this.mssg});

  final Size size;
  final String mssg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(right: size.width * 0.3),
          decoration: BoxDecoration(
            color: Color(0Xffc199cd),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Text(
            mssg,
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
