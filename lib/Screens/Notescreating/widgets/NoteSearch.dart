import 'package:flutter/material.dart';
import 'package:notes/Screens/Notescreating/NoteViewUpdateScreen.dart';
import 'package:notes/model/note_model.dart';

class NotesSearch extends SearchDelegate {
  final List<Note> notes;
  
  BuildContext context;
  NotesSearch(this.notes, this.context);

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

  if (results.isEmpty) {
    return Center(
      child: Text(
        'No notes found',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: results.length,
    itemBuilder: (context, index) {
      final note = results[index];
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteViewUpdateScreen(
                  note: note,
                  noteIndex: notes.indexOf(note),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note Title
                Text(
                  note.title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Note Date
                Text(
                  note.createdDate!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),

                // Important Indicator
                if (note.important ?? false)
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Important',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}
