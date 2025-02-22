import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package
import 'package:notes/Screens/Notescreating/NoteViewUpdateScreen.dart';
import 'package:notes/Screens/Notescreating/widgets/NoteSearch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notes/model/note_model.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  String searchQuery = "";
  Set<int> selectedNotes = {};
  bool isSelectionMode = false;
  final List<Color> cardColors = [
    Colors.orange.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notesList') ?? [];
      setState(() {
        notes =
            notesJson.map((note) => Note.fromMap(json.decode(note))).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notes: $e')),
      );
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((note) => json.encode(note.toMap())).toList();
      await prefs.setStringList('notesList', notesJson);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshNotes,
        child: CustomScrollView(
          slivers: [
            // SliverAppBar (Always Visible)
            SliverAppBar(
              leading: isSelectionMode
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          selectedNotes = {};
                          isSelectionMode = false;
                        });
                      },
                      icon: Icon(Icons.cancel),
                    )
                  : null,
              expandedHeight: 130.0,
              pinned: true,
              floating: true,
              backgroundColor: const Color.fromARGB(255, 247, 220, 190),
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    style: GoogleFonts.pacifico(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isSelectionMode ? Colors.black : Colors.white,
                    ),
                    isSelectionMode
                        ? "${selectedNotes.length} Selected"
                        : 'Notes App',
                    key: ValueKey(isSelectionMode),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://static.vecteezy.com/system/resources/thumbnails/017/506/209/small_2x/collection-of-colorful-variety-paper-note-pad-reminder-sticky-notes-pin-paper-yellow-on-cork-bulletin-board-photo.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                        color: isSelectionMode
                            ? const Color.fromARGB(255, 247, 220, 190)
                            : Colors.black.withOpacity(0.3)),
                  ],
                ),
              ),
              actions: [
                isSelectionMode == true
                    ? IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: _deleteSelectedNotes,
                      )
                    : AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  readOnly: true,
                                  onTap: () {
                                    showSearch(
                                      context: context,
                                      delegate: NotesSearch(notes, context),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 40),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
            // Conditional Sliver: Lottie Animation or Grid View
            if (notes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animation/empty.json', // Path to your Lottie JSON file
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No Notes Found',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns in the grid
                  crossAxisSpacing: 10, // Spacing between columns
                  mainAxisSpacing: 10, // Spacing between rows
                  childAspectRatio: 0.8, // Aspect ratio of each card
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final Note note = notes[index];
                    return GestureDetector(
                      onTap: isSelectionMode
                          ? () => _toggleNoteSelection(index)
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteViewUpdateScreen(
                                    note: note,
                                    noteIndex: index,
                                  ),
                                ),
                              );
                            },
                      onLongPress: () => _enterSelectionMode(index),
                      child: Card(
                        color: selectedNotes.contains(index)
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : null,
                        elevation: 5,
                        shadowColor:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background Image or Placeholder
                            if (note.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  note.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    size: 50,
                                  ),
                                ),
                              ),
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    selectedNotes.contains(index)
                                        ? const Color.fromARGB(255, 165, 150, 150)
                                        : const Color.fromARGB(0, 0, 0, 0),
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Star Icon at Top-Right Corner
                                  selectedNotes.contains(index)
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                              onPressed: () {},
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              )))
                                      : Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            icon: Icon(
                                              note.important
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: note.important
                                                  ? Colors.yellow
                                                  : Colors.white,
                                            ),
                                            onPressed: () =>
                                                _toggleNoteImportance(index),
                                          ),
                                        ),
                                  // Title and Date at Bottom
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title (Max 2 Lines)
                                      Text(
                                        note.title ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: const Color.fromARGB(255, 255, 255, 255),
                                        ),
                                        maxLines: 2, // Limit to 2 lines
                                        overflow: TextOverflow.ellipsis, // Show dots if text exceeds
                                      ),
                                      SizedBox(height: 4),
                                      // Date
                                      Text(
                                        note.createdDate ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: notes.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/noteCreateScreen')
              .then((_) => _refreshNotes());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshNotes() async {
    await _loadNotes();
  }

  void _toggleNoteSelection(int index) {
    setState(() {
      if (selectedNotes.contains(index)) {
        selectedNotes.remove(index);
        if (selectedNotes.isEmpty) isSelectionMode = false;
      } else {
        selectedNotes.add(index);
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      isSelectionMode = true;
      selectedNotes.add(index);
    });
  }

  void _toggleNoteImportance(int index) {
    setState(() {
      notes[index].important = !notes[index].important;
      _saveNotes();
    });
  }

  void _deleteSelectedNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Notes"),
        content: Text(
            "Are you sure you want to delete ${selectedNotes.length} notes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notes = notes
                    .where(
                        (note) => !selectedNotes.contains(notes.indexOf(note)))
                    .toList();
                selectedNotes.clear();
                isSelectionMode = false;
                _saveNotes();
              });
              Navigator.pop(context);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }
}