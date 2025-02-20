import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes/model/note_model.dart'; // Ensure this import points to your Note model

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notesBox');
  String selectedCategory = 'All';
  String searchQuery = "";
  List<String> categories = ['All'];
  Set<int> selectedNotes = {};
  bool isSelectionMode = false;

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
                delegate: NotesSearch(notesBox),
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
              child: ValueListenableBuilder(
                valueListenable: notesBox.listenable(),
                builder: (context, Box<Note> box, _) {
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final key = box.keyAt(index);
                      final Note note = box.getAt(index)!;

                      if ((selectedCategory == 'All' || note.category == selectedCategory) &&
                          (searchQuery.isEmpty || note.title.toLowerCase().contains(searchQuery.toLowerCase()))) {
                        return _NoteCard(
                          note: note,
                          isSelected: selectedNotes.contains(key),
                          onTap: () => _toggleNoteSelection(key),
                          onLongPress: () => _enterSelectionMode(key),
                          onStarPressed: () => _toggleNoteImportance(key),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  );
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
    setState(() {});
  }

  void _showAddTagDialog() {
    TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Tag"),
        content: TextField(controller: tagController, decoration: InputDecoration(hintText: "Enter tag")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (tagController.text.isNotEmpty && !categories.contains(tagController.text)) {
                setState(() {
                  categories.add(tagController.text);
                });
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...categories.map((category) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            );
          }).toList(),
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _showAddTagDialog,
          )
        ],
      ),
    );
  }

  void _toggleNoteSelection(int key) {
    setState(() {
      if (selectedNotes.contains(key)) {
        selectedNotes.remove(key);
        if (selectedNotes.isEmpty) isSelectionMode = false;
      } else {
        selectedNotes.add(key);
      }
    });
  }

  void _enterSelectionMode(int key) {
    setState(() {
      isSelectionMode = true;
      selectedNotes.add(key);
    });
  }

  void _toggleNoteImportance(int key) {
    final Note note = notesBox.get(key)!;
    notesBox.put(key, Note(
      title: note.title,
    
      createdDate: note.createdDate,
      category: note.category,
      important: !note.important, // Toggle importance
    ));
    setState(() {});
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
              for (var key in selectedNotes.toList()) {
                notesBox.delete(key);
              }
              setState(() {
                selectedNotes.clear();
                isSelectionMode = false;
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
  final Box<Note> notesBox;
  NotesSearch(this.notesBox);

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
    final results = notesBox.values.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      children: results.map((note) => ListTile(
        title: Text(note.title),
        subtitle: Text(note.createdDate),
      )).toList(),
    );
  }
}