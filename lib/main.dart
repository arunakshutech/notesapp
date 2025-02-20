import 'package:flutter/material.dart';

import 'package:notes/Screens/NotesScreen.dart';
import 'package:notes/Screens/Notescreating/NotesCreating.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    FlutterQuillLocalizations.delegate,
  ],
  routes: {
      '/noteCreateScreen': (context) => NoteCreateScreen(),
    },
      debugShowCheckedModeBanner: false,
      home: NotesScreen(),
    );
  }
}