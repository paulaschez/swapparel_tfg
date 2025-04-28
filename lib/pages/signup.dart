import 'package:chat_app/service/database.dart';
import 'package:chat_app/service/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/components/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_string/random_string.dart';
import 'home.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String mail = "", name = "", password = "", confirmPassword = "";
  TextEditingController mailCtrl = new TextEditingController();
  TextEditingController nameCtrl = new TextEditingController();
  TextEditingController passwordCtrl = new TextEditingController();
  TextEditingController cnfrmPasswordCtrl = new TextEditingController();

  final _formkey = GlobalKey<FormState>();

  registration() async {
    if (password != "" && password == confirmPassword) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: mail, password: password);

        String Id = randomAlphaNumeric(10);
        Map<String, dynamic> userInfoMap = {
          "Name": nameCtrl.text,
          "E-mail": mailCtrl.text,
          "username": mailCtrl.text.replaceAll("@gmail.com", ""),
          "Photo": "https://cdn-icons-png.flaticon.com/512/17246/17246491.png",
          "Id": Id,
        };
        await DatabaseMethods().addUserDetails(userInfoMap, Id);
        await SharedPreferenceHelper().saveUserId(Id);
        await SharedPreferenceHelper().saveUserEmail(mailCtrl.text);
        await SharedPreferenceHelper().saveUserName(mailCtrl.text.replaceAll("@gmail.com", ""));
        await SharedPreferenceHelper().saverUserDisplayName(nameCtrl.text);
        await SharedPreferenceHelper().saverUserPic("https://cdn-icons-png.flaticon.com/512/17246/17246491.png");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Registered Succesfully",
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> Home()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Password Provided is too weak",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Account already exists",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            // Encabezado con gradiente
            Container(
              height: size.height * 0.25,
              width: size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7f30fe), Color(0xFF6380ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(size.width, size.height * 0.1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.07,
              ), // Margen superior relativo
              child: Column(
                children: [
                  // Título "SignUp"
                  Center(
                    child: Text(
                      "SignUp",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            size.width * 0.07, // Tamaño de fuente relativo
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Create a new Account",
                      style: TextStyle(
                        color: Color(0xFFbbb0ff),
                        fontSize:
                            size.width * 0.05, // Tamaño de fuente relativo
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05), // Espaciado relativo
                  // Contenedor del formulario
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                    ),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.all(
                          size.width * 0.06,
                        ), // Padding relativo
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                title: "Name",
                                icon: Icons.account_circle_outlined,
                                controller: nameCtrl,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: size.height * 0.03),
                              CustomTextField(
                                title: "Email",
                                icon: Icons.mail_outline,
                                controller: mailCtrl,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Email';
                                  } else if (!value.contains("@")) {
                                    return "Enter a valid E-mail";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: size.height * 0.03,
                              ), // Espaciado relativo
                              CustomTextField(
                                title: "Password",
                                icon: Icons.password,
                                obscureText: true,
                                controller: passwordCtrl,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  } else if (value.length < 6) {
                                    return "The password must have at least 6 characters";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: size.height * 0.03,
                              ), // Espaciado relativo
                              CustomTextField(
                                title: "Confirm Password",
                                icon: Icons.password,
                                obscureText: true,
                                controller: cnfrmPasswordCtrl,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Confirm Password';
                                  } else if (value != passwordCtrl.text) {
                                    return "The passwords don't match";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 40.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  Text(
                                    " Sign In Now!",
                                    style: TextStyle(
                                      color: Color(0xFF7f30fe),
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03), // Espaciado relativo
                  // Botón "SignUp"
                  GestureDetector(
                    onTap: () {
                      if (_formkey.currentState!.validate()) {
                        setState(() {
                          mail = mailCtrl.text;
                          name = nameCtrl.text;
                          password = passwordCtrl.text;
                          confirmPassword = cnfrmPasswordCtrl.text;
                        });
                      }

                      registration();
                    },
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.all(
                          size.width * 0.04,
                        ), // Margen relativo
                        width: size.width, // Ancho relativo
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.all(
                              size.width * 0.04,
                            ), // Padding relativo
                            decoration: BoxDecoration(
                              color: Color(0xFF6380fb),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "SignUp",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      size.width *
                                      0.045, // Tamaño de fuente relativo
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
