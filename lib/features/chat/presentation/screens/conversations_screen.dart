import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF553370),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isSearching
                      ? Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search User',
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                            )
                            ,
                          ),
                          style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w500),
                        ),
                      )
                      : Text(
                        "ChatUp",
                        style: TextStyle(
                          color: Color(0Xffc199cd),
                          fontSize:
                              size.width * 0.06, // Tamaño relativo al ancho
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  GestureDetector(
                    onTap: () {
                      _isSearching = true;
        
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Color(0xFF3a2144),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Color(0Xffc199cd),
                        size: size.width * 0.06,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.035,
                  horizontal: size.width * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    ChatEntry(
                      size: size,
                      image: "assets/boy.jpg",
                      name: "Shivam Gupta",
                      mssg: "Hello, What are you doing?",
                      hour: "04:30 PM",
                    ),
                    Divider(
                      height: size.height * 0.02, // Altura del Divider
                      thickness: 1, // Grosor de la línea
                      color: Colors.black12, // Color de la línea
                    ),
                    ChatEntry(
                      size: size,
                      image: "assets/woman.png",
                      name: "Sara Martínez",
                      mssg: "Me está dando un error enorme",
                      hour: "04:30 PM",
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

class ChatEntry extends StatelessWidget {
  const ChatEntry({
    super.key,
    required this.size,
    required this.image,
    required this.name,
    required this.mssg,
    required this.hour,
  });

  final Size size;
  final String image;
  final String name;
  final String mssg;
  final String hour;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.asset(
            image,
            height: size.width * 0.16, // Altura relativa al ancho
            width: size.width * 0.16, // Ancho relativo al ancho
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.01),
              Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: size.width * 0.045, // Tamaño relativo al ancho
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                mssg,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: size.width * 0.04, // Tamaño relativo al ancho
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          hour,
          style: TextStyle(
            color: Colors.black45,
            fontSize: size.width * 0.04, // Tamaño relativo al ancho
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
