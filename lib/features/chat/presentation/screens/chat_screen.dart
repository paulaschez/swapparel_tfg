import 'package:flutter/material.dart';
import 'package:swapparel/features/chat/presentation/widgets/outgoing_message.dart';
import 'package:swapparel/features/chat/presentation/widgets/incoming_message.dart';

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
                padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 50.0),
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
                      mssg: "Hola, tenemos que hablar",
                    ),
                    SizedBox(height: size.height * 0.017),
                    OutgoingMessage(
                      size: size,
                      mssg: "Tenemos que entregar el trabajo hoy",
                    ),
                    SizedBox(height: size.height * 0.017),
                    IncomingMessage(size: size, mssg: "Lo tengo casi listo"),
                    Spacer(),

                    // Barra enviar mensajes
                    SafeArea(
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: EdgeInsets.only(
                            left: size.width * 0.04,
                            right: size.width * 0.03,
                            top: size.width * 0.02,
                            bottom: size.width * 0.02,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 235, 236, 238),
                            borderRadius: BorderRadius.circular(30),
                            //border: Border.all(color:Colors.grey)
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  //textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Type a message",
                                    hintStyle: TextStyle(color: Colors.black45),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: size.height * 0.01,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:  Color.fromARGB(255, 228, 215, 231),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(Icons.send, color:  Color(0Xffc199cd)),
                              ),
                            ],
                          ),
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



