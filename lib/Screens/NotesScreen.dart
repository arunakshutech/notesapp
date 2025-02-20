import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notes/model/note_model.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  String selectedCategory = 'All';
  String searchQuery = "";
  List<String> categories = ['All'];
  Set<int> selectedNotes = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        categories = prefs.getStringList('categories') ?? ['All'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _saveCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('categories', categories);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save categories: $e')),
      );
    }
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notesList') ?? [];
      setState(() {
        notes = notesJson.map((note) => Note.fromMap(json.decode(note))).toList();
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

  void _showTagDialog(int index) {
    String selectedTags = ''; // To store selected tags
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Tags to Note"),
        content: SingleChildScrollView(
          child: Column(
            children: categories.map((tag) {
              return CheckboxListTile(
                title: Text(tag),
                value: selectedTags.contains(tag),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedTags=tag;
                    } else {
                      selectedTags='';
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notes[index].tags = selectedTags;
                _saveNotes();
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? "${selectedNotes.length} Selected" : 'Notes App'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedNotes,
            ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearch(notes),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotes,
        child: Column(
          children: [
            _buildCategoryChips(),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final Note note = notes[index];

                  if ((selectedCategory == 'All' || note.category == selectedCategory) &&
                      (searchQuery.isEmpty || note.title!.toLowerCase().contains(searchQuery.toLowerCase()))) {
                    return Dismissible(
                      key: Key(index.toString()), // Ensure each note has a unique key
                      direction: DismissDirection.endToStart, // Swipe left to right
                      background: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.label, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _showTagDialog(index); // Show tag dialog when swiped
                      },
                      child: _NoteCard(
                        note: note,
                        isSelected: selectedNotes.contains(index),
                        onTap: () => _toggleNoteSelection(index),
                        onLongPress: () => _enterSelectionMode(index),
                        onStarPressed: () => _toggleNoteImportance(index),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/noteCreateScreen').then((_) => _refreshNotes());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshNotes() async {
    await _loadNotes();
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index < categories.length) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: ChoiceChip(
                label: Text(categories[index]),
                selected: selectedCategory == categories[index],
                onSelected: (selected) {
                  setState(() {
                    selectedCategory = categories[index];
                  });
                },
              ),
            );
          } else {
            return IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: _showAddTagDialog,
            );
          }
        },
      ),
    );
  }

    // Add Tag Dialog
  void _showAddTagDialog() {
    TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Tag"),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(hintText: "Enter tag"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String newTag = tagController.text.trim();
              if (newTag.isNotEmpty && !categories.contains(newTag)) {
                setState(() {
                  categories.add(newTag);
                });
                _saveCategories(); // Save to SharedPreferences
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note ${notes[index].important ? 'starred' : 'unstarred'}')),
      );
    });
  }

  void _deleteSelectedNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Notes"),
        content: Text("Are you sure you want to delete ${selectedNotes.length} notes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notes = notes.where((note) => !selectedNotes.contains(notes.indexOf(note))).toList();
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

class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onStarPressed;

  const _NoteCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onStarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          title: Text(note.title ?? "No Title"),
          subtitle: Text(note.createdDate ?? "No Date"),
          trailing: IconButton(
            icon: Icon(note.important ? Icons.star : Icons.star_border),
            onPressed: onStarPressed,
          ),
        ),
      ),
    );
  }
}

class NotesSearch extends SearchDelegate {
  final List<Note> notes;
  NotesSearch(this.notes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = notes.where((note) {
      return note.title!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      children: results.map((note) => ListTile(
        title: Text(note.title!),
        subtitle: Text(note.createdDate!),
      )).toList(),
    );
  }
}