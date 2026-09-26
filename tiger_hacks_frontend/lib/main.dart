import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/views/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlobalState(),
      child: MaterialApp(
        title: 'LiveWire App',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Color(0xFFd16d6a))),
        home: const LoginPage(),
      ),
    );
  }
}
