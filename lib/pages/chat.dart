import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  const Chat({super.key, required this.name});

  final String name;

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF553370),
      body: Container(
        margin: EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_outlined,
                          color: Color(0Xffc199cd),
                        ),
                      ),
                      Center(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            color: Color(0Xffc199cd),
                            fontSize: size.width * 0.065,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 50.0, bottom: 30.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    OutgoingMessage(
                      size: size,
                      mssg: "Hola, tengo que contarte una cosita",
                    ),
                    SizedBox(height: size.height * 0.017),
                    OutgoingMessage(size: size, mssg: "Me caso!!!!"),
                    SizedBox(height: size.height * 0.017),
                    IncomingMessage(size: size, mssg: "NO ME LO PUEDO CREER!"),
                    Spacer(),
                    Material(
                      elevation: 5,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class IncomingMessage extends StatelessWidget {
  const IncomingMessage({super.key, required this.size, required this.mssg});

  final Size size;
  final String mssg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
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
