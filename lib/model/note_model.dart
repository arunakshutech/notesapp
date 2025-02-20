import 'package:hive/hive.dart';
part 'note_model.g.dart';


@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String createdDate;

  @HiveField(2)
  String category;

  @HiveField(3)
  bool important;

  Note({
    required this.title,
    required this.createdDate,
    required this.category,
    required this.important,
  });
}
