import 'dart:io';

import 'package:flutter/material.dart';

import 'screens/all_izin_screen.dart';
import 'screens/detail_cuti_screen.dart';
import 'screens/features_screen.dart';
import 'screens/home_screen.dart';
import 'screens/izin_screen.dart';
import 'screens/list_cuti_screen.dart';
import 'screens/login_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/workspace_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreatDaY HR',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/features': (context) => const FeaturesScreen(),
        '/izin': (context) => const IzinScreen(),
        '/list-cuti': (context) => const ListCutiScreen(),
        '/all-izin': (context) => const AllIzinScreen(),
        '/detail-cuti': (context) => DetailCutiScreen(
              cutiId: (ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>)['id'],
            ),
        '/posts': (context) => const PostsScreen(),
        '/workspace': (context) => const WorkspaceScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
