import 'package:chat_app/components/custom_textfield.dart';
import 'package:chat_app/service/database.dart';
import 'package:chat_app/service/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // Variables para almacenar los datos del formulario
  String mail = "", password = "", name = "", pic = "", username = "", id = "";
  // Controladores para los campos de texto
  TextEditingController userMailCtrl = TextEditingController();
  TextEditingController userPasswordCtrl = TextEditingController();

  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // --- Función para manejar el login del usuario ---
  userLogin() async {
    print("DEBUG: userLogin() llamado."); // Punto de inicio
    if (!mounted) return; // Verifica si el widget todavía está montado

    try {
      print("DEBUG: Intentando iniciar sesión con Firebase Auth para el email: $mail");
      // Intenta iniciar sesión con el email y contraseña proporcionados
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mail,
        password: password,
      );
      print("DEBUG: ¡Inicio de sesión con Firebase Auth exitoso! UID: ${userCredential.user?.uid}");

      print("DEBUG: Buscando usuario en Firestore con email: $mail");
      // Busca la información del usuario en Firestore usando el email
      QuerySnapshot querySnapshot = await DatabaseMethods().getUserByEmail(
        mail,
      );

      print("DEBUG: Firestore encontró ${querySnapshot.docs.length} documentos para ese email.");
      // Verifica si se encontró algún documento
      if (querySnapshot.docs.isNotEmpty) {
        // Extrae los datos del primer documento encontrado
        name = "${querySnapshot.docs[0]["Name"]}";
        username = "${querySnapshot.docs[0]["username"]}";
        pic = "${querySnapshot.docs[0]["Photo"]}";
        id = querySnapshot.docs[0].id;
        print("DEBUG: Datos extraídos - Name: $name, Username: $username, Pic: $pic, ID: $id");

        print("DEBUG: Guardando datos en SharedPreferences...");
        // Guarda la información del usuario en SharedPreferences
        await SharedPreferenceHelper().saverUserDisplayName(name);
        await SharedPreferenceHelper().saveUserEmail(mail); // Guarda el email usado para login
        await SharedPreferenceHelper().saveUserId(id);
        await SharedPreferenceHelper().saverUserPic(pic);
        await SharedPreferenceHelper().saveUserName(username);
        print("DEBUG: Datos guardados en SharedPreferences.");

        // Muestra un mensaje de éxito
        if (mounted) { // Verifica de nuevo antes de usar context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Succesfully", style: TextStyle(fontSize: 20.0)),
            ),
          );
          print("DEBUG: Navegando a la pantalla Home...");
          // Navega a la pantalla Home, reemplazando la pantalla actual
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
        }
      } else {
        // Si no se encontraron documentos en Firestore para ese email
        print("DEBUG: ERROR - No se encontraron datos en Firestore para el email: $mail después de un login exitoso.");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Login successful, but couldn't fetch user data.",
                style: TextStyle(fontSize: 18.0, color: Colors.black),
              ),
               backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      // Captura errores específicos de FirebaseAuth
      print("DEBUG: FirebaseAuthException capturada - Código: ${e.code}, Mensaje: ${e.message}");
      String errorMessage = "An error occurred.";
      if (e.code == 'user-not-found') {
        errorMessage = "No User Found for that Email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong Password Provided by User";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      } else if (e.code == 'invalid-credential'){
         errorMessage = "Invalid credentials. Please check email and password."; // Más genérico para credenciales inválidas
      }

      if (mounted) { // Verifica antes de usar context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      // Captura cualquier otro error inesperado
      print("DEBUG: Error general capturado en userLogin: $e");
      if (mounted) { // Verifica antes de usar context
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "An unexpected error occurred: $e",
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print("DEBUG: Construyendo widget SignIn.");

    return Scaffold(
      body: Container(
        // Usa SingleChildScrollView para evitar overflow si el teclado aparece
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // --- Fondo Decorativo Superior ---
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
              // --- Contenido Principal ---
              Padding(
                padding: EdgeInsets.only(
                  top: size.height * 0.07, // Margen superior relativo
                ),
                child: Column(
                  children: [
                    // --- Títulos ---
                    Center(
                      child: Text(
                        "SignIn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.07, // Tamaño de fuente relativo
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "Login to your account",
                        style: TextStyle(
                          color: Color(0xFFbbb0ff),
                          fontSize: size.width * 0.05, // Tamaño de fuente relativo
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05), // Espaciado relativo

                    // --- Formulario ---
                    Form(
                      key: _formKey,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: size.width * 0.05, // Margen horizontal relativo
                        ),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.06, // Padding horizontal relativo
                              vertical: size.height * 0.03, // Padding vertical relativo (ajustado)
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Campo Email ---
                                CustomTextField(
                                  title: "Email",
                                  icon: Icons.mail_outline,
                                  controller: userMailCtrl,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Email';
                                    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) { // Validación de email más robusta
                                      return "Enter a valid E-mail";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: size.height * 0.03), // Espaciado relativo

                                // --- Campo Contraseña ---
                                CustomTextField(
                                  title: "Password",
                                  icon: Icons.password,
                                  controller: userPasswordCtrl,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Password';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: size.height * 0.01), // Espaciado relativo

                                // --- Enlace Olvidó Contraseña ---
                                Container(
                                  alignment: Alignment.bottomRight,
                                  // Añadir GestureDetector si quieres que sea clickeable
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.black54, // Color más suave
                                      fontSize: size.width * 0.04, // Tamaño relativo
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(height: size.height * 0.05), // Espaciado relativo (ajustado)

                                // --- Botón SignIn ---
                                GestureDetector(
                                  onTap: () {
                                    print("DEBUG: Botón SignIn presionado.");
                                    // Valida el formulario
                                    if (_formKey.currentState!.validate()) {
                                      print("DEBUG: Formulario validado.");
                                      // Actualiza las variables 'mail' y 'password' con el texto de los controladores
                                      setState(() {
                                        mail = userMailCtrl.text.trim(); // trim() para quitar espacios extra
                                        password = userPasswordCtrl.text.trim();
                                        print("DEBUG: Email actualizado a: $mail"); // Verifica el valor
                                      });
                                      // Llama a la función de login
                                      userLogin();
                                    } else {
                                       print("DEBUG: Formulario NO validado.");
                                    }
                                  },
                                  child: Center(
                                    child: Container(
                                      width: size.width * 0.33, // Ancho relativo
                                      child: Material(
                                        elevation: 5.0,
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            size.width * 0.03, // Padding relativo
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF6380fb),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "SignIn",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: size.width * 0.05, // Tamaño relativo
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02), // Espacio antes del texto SignUp
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04), // Espaciado relativo (ajustado)

                    // --- Texto y Enlace a SignUp ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.black87, // Color más suave
                            fontSize: size.width * 0.04, // Tamaño relativo
                          ),
                        ),
                        // Añadir GestureDetector si quieres que sea clickeable para ir a SignUp
                        Text(
                          " Sign Up Now!",
                          style: TextStyle(
                            color: Color(0xFF7f30fe),
                            fontSize: size.width * 0.04, // Tamaño relativo
                            fontWeight: FontWeight.bold, // Más destacado
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.04), // Espacio al final
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}