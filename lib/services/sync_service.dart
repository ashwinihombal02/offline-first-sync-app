import 'package:hive/hive.dart';
import '../models/sync_action_model.dart';
import 'firebase_service.dart';
import 'hive_service.dart';

class SyncService {
  final FirebaseService firebaseService;

  SyncService(this.firebaseService);

  Future<void> processQueue() async {
    final box = Hive.box(HiveService.queueBox);
    final notesBox = Hive.box(HiveService.notesBox);

    for (final key in box.keys.toList()) {
      final raw = Map<String, dynamic>.from(box.get(key));
      final action = SyncActionModel.fromMap(raw);

      try {
        if (action.type == 'delete_note') {
          await firebaseService.deleteNote(action.payload['id']);
        } else {
          await firebaseService.upsertNote(action.payload);

          final noteId = action.payload['id'];
          if (noteId != null) {
            final current = notesBox.get(noteId);
            if (current != null) {
              await notesBox.put(noteId, {
                ...Map<String, dynamic>.from(current),
                'synced': true,
              });
            }
          }
        }

        print('SYNC SUCCESS -> ${action.idempotencyKey}');
        await box.delete(key);
      } catch (e) {
        print('SYNC FAILED -> ${action.idempotencyKey}');

        if (action.retryCount < 1) {
          await Future.delayed(const Duration(seconds: 2));

          await box.put(
            key,
            SyncActionModel(
              idempotencyKey: action.idempotencyKey,
              type: action.type,
              payload: action.payload,
              retryCount: action.retryCount + 1,
            ).toMap(),
          );
        }
      }
    }

    print('QUEUE SIZE -> ${box.length}');
  }
}