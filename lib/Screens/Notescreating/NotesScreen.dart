import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Add this import
import 'package:notes/Screens/Notescreating/widgets/NoteCard.dart';
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
  String selectedCategory = 'All';
  String searchQuery = "";
  List<String> categories = ['All'];
  List<String> tags = [];
  Set<int> selectedNotes = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadCategories();
  }
// Show confirmation dialog for deletion
  void _showDeleteDialog(String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Category'),
          content: Text('Are you sure you want to delete "$category"? All notes under this category will also be deleted.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteCategory(category);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete category and associated notes
  void _deleteCategory(String category) {
    setState(() {
      // Remove category
      categories.remove(category);

      // Remove notes under the deleted category
      notes.removeWhere((note) => note.tags == category);
    });
    _saveCategories();
    _saveNotes();
  }

  Future<void> _loadCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load saved categories from SharedPreferences
      List<String> savedCategories = prefs.getStringList('categories') ?? [];

      // Ensure 'All' is always the first category
      setState(() {
        categories = ['All', ...savedCategories];
        tags = [
          'None',
          ...savedCategories
        ]; // If you also want to load tags similarly
      });

      print(tags); // For debugging
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _saveCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> categoriesToSave =
          categories.where((category) => category != 'All').toList();
      await prefs.setStringList('categories', categoriesToSave);
      _loadCategories();
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

  void _showTagDialog(int index) {
    String selectedTag = notes[index].tags ?? ''; // Initialize with current tag

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Tags to Note"),
              content: SingleChildScrollView(
                child: Column(
                  children: tags.map((tag) {
                    return RadioListTile(
                      key: Key(tag),
                      title: Text(tag),
                      value: tag,
                      groupValue: selectedTag,
                      onChanged: (value) {
                        setState(() {
                          selectedTag = value.toString();
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
                      notes[index].tags = selectedTag;
                      _saveNotes();
                      _loadNotes();
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: isSelectionMode?IconButton(onPressed:()=>{
          
          setState(() {
            selectedNotes={};
          isSelectionMode=false;
        })}, icon:Icon(Icons.cancel)):null,
        title: Text(
            isSelectionMode ? "${selectedNotes.length} Selected" : 'Notes App'),
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

                  if ((selectedCategory == 'All' ||
                          note.tags == selectedCategory) &&
                      (searchQuery.isEmpty ||
                          note.title!
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))) {
                    return Slidable(
                      key: Key(index
                          .toString()), // Ensure each note has a unique key
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) => _showTagDialog(index),
                            backgroundColor: Colors.blue,
                            icon: Icons.label,
                            label: 'Add To Tag',
                          ),
                        ],
                      ),
                      child: NoteCard(
                        note: note,
                        index:index,
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

  // Build category chips
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
              child: GestureDetector(
                onLongPress: () {
                  if(categories[index]!='All'){
                        _showDeleteDialog(categories[index]);
                  }
                
                },
                child: ChoiceChip(
                  label: Text(categories[index]),
                  selected: selectedCategory == categories[index],
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                  },
                ),
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
