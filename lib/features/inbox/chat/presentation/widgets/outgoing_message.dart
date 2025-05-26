import 'package:flutter/material.dart';

class OutgoingMessage extends StatelessWidget {
  const OutgoingMessage({super.key, required this.size, required this.mssg});

  final Size size;
  final String mssg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(left: size.width * 0.3),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 232, 234, 237),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
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