import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notes/Screens/Notescreating/NotesScreen.dart';
import 'package:notes/Screens/Notescreating/NotesCreating.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../model/note_model.dart';

class NoteViewUpdateScreen extends StatefulWidget {
  final Note note;
  final int noteIndex;

  const NoteViewUpdateScreen({
    Key? key,
    required this.note,
    required this.noteIndex,
  }) : super(key: key);

  @override
  _NoteViewUpdateScreenState createState() => _NoteViewUpdateScreenState();
}

class _NoteViewUpdateScreenState extends State<NoteViewUpdateScreen> {
 quill.QuillController _controller = QuillController.basic();
  late TextEditingController _titleController;
  bool _isEditing = false;
  bool _isSaving = false;


@override
void initState() {
  super.initState();
  _titleController = TextEditingController(text: widget.note.title);
  
  // Check if content is not null and not empty
  if (widget.note.content != null && widget.note.content!.isNotEmpty) {
    try {
      // Decode the JSON content
      final documentJson = jsonDecode(widget.note.content!);

      // Check if it's a valid Delta format (List of operations)
      if (documentJson is List) {
       
        _controller = quill.QuillController(readOnly: true,
          document: quill.Document.fromJson(documentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
         
      } else {
        // If not a valid format, initialize with an empty document
        _controller = quill.QuillController.basic();
          _controller.readOnly;
      }
    } catch (e) {
      // Handle JSON decoding errors
      print('Error loading content: $e');
      _controller = quill.QuillController.basic();
    }
  } else {
    // If content is null or empty, initialize with an empty document
    _controller = quill.QuillController.basic();
    _controller.readOnly;
  }
}


  Future<void> _updateNote() async {
     FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final updatedDate = DateTime.now().toString().substring(0, 16);

    if (title.isNotEmpty && content.isNotEmpty) {
      final updatedNote = Note(
        title: title,
        content: content,
        createdDate: widget.note.createdDate,
        important: widget.note.important,
        tags:widget.note.tags,
        category:widget.note.category
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? notesList = prefs.getStringList('notesList') ?? [];
      notesList[widget.noteIndex] = jsonEncode(updatedNote.toMap());
      await prefs.setStringList('notesList', notesList);

      @override
      void dispose() {
        _controller.dispose();
        super.dispose();
      }

      setState(() {
        _isSaving = false;
      });
     

   Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => NotesScreen()),
  (Route<dynamic> route) => false,
);



    } else {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _controller.readOnly = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Note' : 'View Note',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.done),
                onPressed: _isSaving ? null : _updateNote,
                tooltip: 'Save Note',
                color: Colors.white,
              ),
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white,Color(444)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter title...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                enabled: _isEditing,
              ),
            ),
            const SizedBox(height: 20),
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
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all( 10),
                  child: quill.QuillEditor.basic(
                  controller: _controller,
                  
                  config: quill.QuillEditorConfig(
                
                  ),
                ),
              ),
            ),
            if (_isEditing) const SizedBox(height: 10),
            if (_isEditing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height:90,
                  
                  child: quill.QuillSimpleToolbar(
                    controller: _controller,
                    config: const quill.QuillSimpleToolbarConfig(
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
              ),
          ],
        ),
      ),
    );
  }
}