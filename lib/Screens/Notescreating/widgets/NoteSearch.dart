

import 'package:flutter/material.dart';
import 'package:notes/model/note_model.dart';

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