import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/util.dart';
import 'package:tiger_hacks_frontend/views/login_page.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_main_view.dart';

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
        debugShowCheckedModeBanner: false,
        title: 'LiveWire App',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: themeSeedColor)),
        home: PersonalMainView(),
      ),
    );
  }
}
