import 'package:flutter/material.dart';
import 'package:notes/Screens/Notescreating/NoteViewUpdateScreen.dart';
import 'package:notes/model/note_model.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onStarPressed;
  final int index;

  const NoteCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onStarPressed, 
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap:()=>{
    
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NoteViewUpdateScreen(
      note: note,
      noteIndex:index,
    ),
  ),
)},
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.5) : const Color.fromARGB(255, 162, 255, 204),
        elevation: 8, // Increased elevation for a more prominent shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // More rounded corners
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Add margin
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag Button
            
            // Note Content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        note.title ?? "No Title",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8), // Spacing between title and content
                      // Content
                      // Text(
                      //   note.content ?? "No Content",
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.grey[700],
                      //   ),
                      //   maxLines: 2, // Limit content to 2 lines
                      //   overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                      // ),
                    ],
                  ),
                ),

                if (note.tags != null && note.tags != 'None')
              Padding(
                padding: EdgeInsets.only(right: 46, top: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    note.tags!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ],
            ),

            // Star Icon and Date
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Star Icon
                  IconButton(
                    icon: Icon(
                      note.important ? Icons.star : Icons.star_border,
                      color: note.important ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                    onPressed: onStarPressed,
                  ),

                  

                  // Date
                  Text(
                    note.createdDate ?? "No Date",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}