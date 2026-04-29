import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/sync_action_model.dart';
import '../services/hive_service.dart';

class NotesRepository {
  final uuid = const Uuid();

  List<NoteModel> getLocalNotes() {
    final box = Hive.box(HiveService.notesBox);

    return box.values
        .map((e) => NoteModel.fromMap(
      Map<String, dynamic>.from(e),
    ))
        .toList();
  }

  Future<void> addNote(String title) async {
    final id = uuid.v4();

    final note = NoteModel(
      id: id,
      title: title,
      isSaved: false,
      updatedAt: DateTime.now(),
    );

    Hive.box(HiveService.notesBox)
        .put(id, note.toMap());

    final action = SyncActionModel(
      idempotencyKey: 'note_$id',
      type: 'add_note',
      payload: note.toMap(),
    );

    Hive.box(HiveService.queueBox)
        .put(action.idempotencyKey, action.toMap());

    print(
      'QUEUE SIZE -> ${Hive.box(HiveService.queueBox).length}',
    );
  }
}