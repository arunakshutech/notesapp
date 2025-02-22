import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:notes/Screens/Notescreating/NotesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/note_model.dart';

class NoteCreateScreen extends StatefulWidget {
  const NoteCreateScreen({super.key});

  @override
  _NoteCreateScreenState createState() => _NoteCreateScreenState();
}

class _NoteCreateScreenState extends State<NoteCreateScreen> {
  final quill.QuillController _controller = quill.QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_onFocusChange);
    _contentFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isToolbarVisible = _contentFocusNode.hasFocus;
    });
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
  Future<void> saveNote() async {
    final title = _titleController.text.trim();
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final createdDate = DateTime.now().toString().substring(0, 16);

    if (title.isNotEmpty && content.isNotEmpty) {
      final imageUrl = await fetchImageUrl(title);

      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdDate: createdDate,
        important: false,
        imageUrl: imageUrl,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? notesList = prefs.getStringList('notesList') ?? [];
      notesList.add(jsonEncode(newNote.toMap()));
      await prefs.setStringList('notesList', notesList);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NotesScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.black,
                  ),
                  TextButton.icon(
                    onPressed: saveNote,
                    icon: const Icon(Icons.save_rounded, color: Colors.black),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color.fromARGB(0, 255, 255, 255),
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
              ),
            ),

            // Content Editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor.basic(
                  controller: _controller,
                  focusNode: _contentFocusNode,
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing your note...',
                    scrollable: true,
                    expands: false,
                  ),
                ),
              ),
            ),

            // Toolbar
            if (_isToolbarVisible)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(0, 245, 245, 245),
                  border: Border(
                    top: BorderSide(
                      color: const Color.fromARGB(0, 224, 224, 224),
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
