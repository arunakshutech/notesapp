import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:notes/Screens/Notescreating/NoteViewUpdateScreen.dart';
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
    _loadCategories();
  }

  // Show confirmation dialog for deletion
  void _showDeleteDialog(String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Category'),
          content: Text(
              'Are you sure you want to delete "$category"? All notes under this category will also be deleted.'),
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
  
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index < categories.length) {
            final category = categories[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onLongPress: () {
                  if (category != 'All') {
                    _showDeleteDialog(category);
                  }
                },
                child: ChoiceChip(
                  key: ValueKey(category),
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
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
      body: RefreshIndicator(
        onRefresh: _refreshNotes,
        child: CustomScrollView(
          slivers: [
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
              expandedHeight: 200.0,
              pinned: true,
              floating: true,
              backgroundColor: const Color.fromARGB(255, 247, 220, 190),
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    style: TextStyle(
                        color: isSelectionMode ? Colors.black : Colors.white),
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
            // Sticky Category Chips
            SliverPersistentHeader(
              floating: true,
              pinned: true,
              delegate: StickyHeaderDelegate(
                child: _buildCategoryChips(),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final Note note = notes[index];
                  if ((selectedCategory == 'All' ||
                          note.tags == selectedCategory) &&
                      (searchQuery.isEmpty ||
                          note.title!
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))) {
                    return Slidable(
                      key: Key(index.toString()),
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
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selectedNotes.contains(index)
                              ? const Color.fromARGB(255, 130, 130, 130)
                              : cardColors[index % cardColors.length],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: note.tags != null
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    note.tags!,
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                          title: Text(
                            note.title ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            note.createdDate ?? '',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              note.important ? Icons.star : Icons.star_border,
                              color:
                                  note.important ? Colors.yellow : Colors.grey,
                            ),
                            onPressed: () => _toggleNoteImportance(index),
                          ),
                          onTap: isSelectionMode
                              ? () => _toggleNoteSelection(index)
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NoteViewUpdateScreen(
                                        note: note,
                                        noteIndex: index,
                                      ),
                                    ),
                                  );
                                },
                          onLongPress: () => _enterSelectionMode(index),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
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
            onPressed: () async {
              String newTag = tagController.text.trim();
              if (newTag.isNotEmpty && !categories.contains(newTag)) {
                setState(() {
                  categories.add(newTag);
                });
                _saveCategories(); // Save to SharedPreferences
                 await _saveCategories(); // Save the updated list to SharedPreferences
                await _loadCategories();
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

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 50; // Minimum height of the header
  @override
  double get maxExtent => 50; // Maximum height of the header

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Background color of the header
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    // Return true to force the delegate to rebuild when the child changes
    return oldDelegate.child != child;
  }
}