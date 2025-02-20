import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:notes/Screens/NotesScreen.dart';
import 'package:notes/Screens/Notescreating/NotesCreating.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notes/model/note_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notesBox');
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox('tagsBox');
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
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