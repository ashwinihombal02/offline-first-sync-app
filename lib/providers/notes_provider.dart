import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_model.dart';
import '../repositories/notes_repository.dart';
import '../services/firebase_service.dart';
import '../services/sync_service.dart';

/// Repository Provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

/// Firebase Service Provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return SyncService(firebaseService);
});

/// Notes StateNotifier Provider
final notesProvider =
StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  final repository = ref.read(notesRepositoryProvider);
  return NotesNotifier(repository);
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final NotesRepository repository;

  NotesNotifier(this.repository) : super([]) {
    loadNotes();
  }

  /// Load cached notes instantly (local-first UX)
  void loadNotes() {
    state = repository.getLocalNotes();
  }

  /// Add note offline-first
  Future<void> addNote(String title) async {
    await repository.addNote(title);
    loadNotes();
  }

  /// Refresh local cache
  void refresh() {
    loadNotes();
  }
}