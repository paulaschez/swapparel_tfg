import 'package:chat_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:chat_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chat_app/features/chat/presentation/screens/conversations_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/services/local_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Singleton de FirebaseAuth, Firestore y almacenamiento local
        Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
        Provider<ILocalStorageService>(
          create: (_) => LocalStorageServiceImpl(),
        ),

        // Repositorio (Depende de los servicios anteriores)
        ProxyProvider3<
          FirebaseAuth,
          FirebaseFirestore,
          ILocalStorageService,
          AuthRepository
        >(
          update:
              (_, auth, firestore, storageService, __) => AuthRepositoryImpl(
                firebaseAuth: auth,
                firestore: firestore,
                localStorageService: storageService,
              ),
        ),

        ChangeNotifierProvider<AuthProviderC>(
          create:
              (context) =>
                  AuthProviderC(authRepository: context.read<AuthRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

// Widget para decidir si mostrar Login o Home basado en Auth
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // Esperando conexión
        }
        if (snapshot.hasData) {
          // Usuario está logueado
          return Home(); 
        } else {
          // Usuario no está logueado
          return SignIn(); 
        }
      },
    );
  }
}
