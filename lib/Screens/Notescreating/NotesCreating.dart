import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../model/note_model.dart';


class NoteCreateScreen extends StatefulWidget {
  const NoteCreateScreen({super.key});

  @override
  _NoteCreateScreenState createState() => _NoteCreateScreenState();
}

class _NoteCreateScreenState extends State<NoteCreateScreen> {
  final quill.QuillController _controller = quill.QuillController.basic();
  final TextEditingController _titleController = TextEditingController();

  Future<void> saveNote() async {
    final title = _titleController.text.trim();
    final content = _controller.document.toPlainText().trim();
    final createdDate = DateTime.now().toString().substring(0, 16);

    if (title.isNotEmpty && content.isNotEmpty) {
      final newNote = Note(
        title: title,
        content: content,
        createdDate: createdDate,
        important: false,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? notesList = prefs.getStringList('notesList') ?? [];
      notesList.add(jsonEncode(newNote.toMap()));
      await prefs.setStringList('notesList', notesList);

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Title and content cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<List<Note>> getNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? notesList = prefs.getStringList('notesList') ?? [];
    return notesList.map((note) => Note.fromMap(jsonDecode(note))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Note',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: Icon(Icons.done),
              onPressed: saveNote,
              tooltip: 'Save Note',
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter title...',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      BorderSide(color: Colors.deepPurple, width: 2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: QuillEditor.basic(
                  controller: _controller,
                  config: const QuillEditorConfig(),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: QuillSimpleToolbar(
                controller: _controller,
                config: const QuillSimpleToolbarConfig(
                  showClearFormat: true,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showQuote: false,
                  showCodeBlock: false,
                  showDirection: false,
                  showIndent: false,
                  showAlignmentButtons: false,
                  showDividers: false,
                  showSearchButton: false,
                  showLineHeightButton: false,
                  showSuperscript: false,
                  showHeaderStyle: false,
                  showFontFamily: false,
                  showSubscript: false,
                  showFontSize: false,
                  showSmallButton: false,
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  showClipboardPaste: false,
                  showJustifyAlignment: false,
                  showInlineCode: false,
                  showRightAlignment: false,
                  showStrikeThrough: false,
                  showLeftAlignment: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
