import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/util.dart';
import 'package:tiger_hacks_frontend/views/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SharedPreferencesAsync().clear();
    return ChangeNotifierProvider(
      create: (_) => GlobalState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LiveWire App',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: themeSeedColor)),
        home: LoginPage(),
      ),
    );
  }
}
