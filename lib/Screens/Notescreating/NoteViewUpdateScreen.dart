import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:notes/Screens/Notescreating/NotesScreen.dart';
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
  quill.QuillController _controller = quill.QuillController.basic();
  late TextEditingController _titleController;
  bool _isEditing = false;
  bool _isSaving = false;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);

    // Initialize QuillController with note content
    if (widget.note.content != null && widget.note.content!.isNotEmpty) {
      try {
        final documentJson = jsonDecode(widget.note.content!);
        _controller = quill.QuillController(
          document: quill.Document.fromJson(documentJson),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: !_isEditing, // Set read-only based on edit mode
        );
      } catch (e) {
        print('Error loading content: $e');
        _controller = quill.QuillController.basic();
      }
    } else {
      _controller = quill.QuillController.basic();
    }
  }


Future<String?> fetchImageUrl(String query) async {
  const String accessKey = 'kLkfb1Facfj74y-trU7FzeiIT6iw8XsFO6ijo0xDk90';
  final String url =
      'https://api.unsplash.com/search/photos?query=$query&client_id=$accessKey';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the response contains any results
      if (data['total'] == 0) {
        // If no results, fetch a default image for the keyword "Notes"
        return await fetchImageUrl('Notes');
      } else {
        final results = data['results'];
        if (results.isNotEmpty) {
          return results[0]['urls']['small']; // Return the first image URL
        }
      }
    } else {
      print('Failed to fetch image: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching image: $e');
  }

  return null; // Return null if no image is found
}
Future<void> _updateNote() async {
  FocusScope.of(context).unfocus();
  setState(() {
    _isSaving = true;
  });

  final title = _titleController.text.trim();
  final content = jsonEncode(_controller.document.toDelta().toJson());
  DateTime.now().toString().substring(0, 16);
  final imageUrl = await fetchImageUrl(title);

  if (title.isNotEmpty && content.isNotEmpty) {
    final updatedNote = Note(
      id: widget.note.id,  // Use existing note's ID
      title: title,
      content: content,
      createdDate: widget.note.createdDate,
      important: widget.note.important,
      tags: widget.note.tags,
      category: widget.note.category,
      imageUrl: imageUrl,
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? notesList = prefs.getStringList('notesList') ?? [];

    // Decode all notes to find and update by ID
    List<Note> notes = notesList.map((item) => Note.fromMap(jsonDecode(item))).toList();
    int index = notes.indexWhere((note) => note.id == widget.note.id);

    if (index != -1) {
      notes[index] = updatedNote;
      List<String> updatedNotesList = notes.map((note) => jsonEncode(note.toMap())).toList();
      await prefs.setStringList('notesList', updatedNotesList);
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
      _controller.readOnly = !_isEditing; // Toggle read-only mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
       leading:IconButton(onPressed:(){
        Navigator.pop(context);
       }, icon: Icon(Icons.arrow_back_ios_new)),
        elevation: 0,
       
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: _isSaving
                    ? const CircularProgressIndicator(color: Color.fromARGB(255, 0, 0, 0),)
                    : const Icon(Icons.done),
                onPressed: _isSaving ? null : _updateNote,
                tooltip: 'Save Note',
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          if (_isEditing == false)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color.fromARGB(0, 224, 224, 224),
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                focusNode: _titleFocusNode,
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                readOnly: !_isEditing, // Title is editable only in edit mode
              ),
            ),

            // Content Editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _contentFocusNode,
                  // Content is editable only in edit mode
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing your note...',
                    scrollable: true,
                    expands: false,
                  ),
                ),
              ),
            ),

            // Toolbar (visible only in edit mode)
            if (_isEditing)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: QuillSimpleToolbar(
                  controller: _controller,
                  config: const QuillSimpleToolbarConfig(
                    showClipboardCopy: false,
                    showDividers: false,
                    showClearFormat: false,
                    showSmallButton: false,
                    showHeaderStyle: false,
                    showBoldButton: true,
                    showClipboardPaste: false,
                    showInlineCode: false,
                    showItalicButton: false,
                    showUnderLineButton: true,
                    showListBullets: false,
                    showClipboardCut: false,
                    showListNumbers: true,
                    showLeftAlignment: false,
                    showRightAlignment: false,
                    showCenterAlignment: false,
                    showDirection: false,
                    showJustifyAlignment: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showLineHeightButton: false,
                    showQuote: false,
                    showCodeBlock: false,
                    showStrikeThrough: false,
                    showIndent: false,
                    showLink: false,
                    showAlignmentButtons: false,
                    showSearchButton: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showBackgroundColorButton: false,
                    showColorButton: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
