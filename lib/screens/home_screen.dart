import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../repositories/notes_repository.dart';
import '../services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesRepository _repository = NotesRepository();
  final SyncService _syncService = SyncService(FirebaseService());
  final TextEditingController _noteController = TextEditingController();

  List<dynamic> notes = [];
  int pendingQueue = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final notesBox = Hive.box(AppConstants.notesBox);
    final queueBox = Hive.box(AppConstants.queueBox);

    setState(() {
      notes = notesBox.values.toList();
      pendingQueue = queueBox.length;
    });

    AppLogger.queue(pendingQueue);
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    await _repository.addNote(text);
    _noteController.clear();
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved — queued for sync')),
    );
  }

  Future<void> _toggleSaved(Map note) async {
    final notesBox = Hive.box(AppConstants.notesBox);
    final queueBox = Hive.box(AppConstants.queueBox);
    final noteId = note['id'];
    final current = notesBox.get(noteId);
    if (current == null) return;

    final updated = {
      ...Map<String, dynamic>.from(current),
      'saved': !(current['saved'] ?? false),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await notesBox.put(noteId, updated);

    final action = {
      'idempotencyKey': 'note_$noteId',
      'type': AppConstants.toggleSave,
      'payload': updated,
      'retryCount': 0,
    };
    await queueBox.put(action['idempotencyKey'], action);

    AppLogger.info('Bookmark toggled locally');
    _loadData();
  }

  Future<void> _deleteNote(Map note) async {
    final notesBox = Hive.box(AppConstants.notesBox);
    final queueBox = Hive.box(AppConstants.queueBox);
    final noteId = note['id'];

    final hasPending = queueBox.containsKey('note_$noteId');

    if (hasPending) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete note'),
          content: const Text(
            'This note has a pending sync. Do you want to delete it locally only, or also remove it from the sync queue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'local_only'),
              child: const Text('Delete locally only'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'clear_queue'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete & clear queue'),
            ),
          ],
        ),
      );

      if (result == null || result == 'cancel') return;

      await notesBox.delete(noteId);

      if (result == 'clear_queue') {
        // Remove from queue entirely — nothing to sync
        await queueBox.delete('note_$noteId');
      } else {
        // Keep a delete_note action so Firebase still gets cleaned up
        await queueBox.put('note_$noteId', {
          'idempotencyKey': 'note_$noteId',
          'type': 'delete_note',
          'payload': {'id': noteId},
          'retryCount': 0,
        });
      }
    } else {
      // No pending queue entry — note is already synced, just delete normally
      await notesBox.delete(noteId);
      await queueBox.put('note_$noteId', {
        'idempotencyKey': 'note_$noteId',
        'type': 'delete_note',
        'payload': {'id': noteId},
        'retryCount': 0,
      });
    }

    AppLogger.info('Note deleted locally');
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );
  }

  Future<bool> _hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _manualSync() async {
    if (_isSyncing) return;

    final isOnline = await _hasConnectivity();

    if (!isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No internet connection. Please try again when you are online.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;  // bail out early, don't touch the queue
    }

    setState(() => _isSyncing = true);

    final before = pendingQueue;
    await _syncService.processQueue();
    _loadData();

    setState(() => _isSyncing = false);

    if (!mounted) return;
    final success = pendingQueue == 0 && before > 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'All notes synced to cloud'
              : 'Sync failed — check Firebase rules',
        ),
        backgroundColor:
        success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  Widget _buildSyncBadge() {
    final isPending = pendingQueue > 0;
    final bg = isPending
        ? const Color(0xFFFFF3CD)
        : const Color(0xFFD4EDDA);
    final fg = isPending
        ? const Color(0xFF856404)
        : const Color(0xFF155724);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(
            color: fg,
            animate: isPending,
          ),
          const SizedBox(width: 6),
          Text(
            isPending ? '$pendingQueue pending' : 'All synced',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.note_outlined,
          iconBg: const Color(0xFFE8F4FD),
          iconColor: const Color(0xFF1A73E8),
          value: notes.length.toString(),
          label: 'Total notes',
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.sync,
          iconBg: const Color(0xFFFFF3CD),
          iconColor: const Color(0xFF856404),
          value: pendingQueue.toString(),
          label: 'Pending sync',
        )),
      ],
    );
  }

  // ── Add note ───────────────────────────────────────────────────────────────

  Widget _buildAddNoteCard() {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('New note'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  onSubmitted: (_) => _addNote(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a note...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade600,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OutlineButton(
                icon: Icons.save_outlined,
                label: 'Save',
                onPressed: _addNote,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sync bar ───────────────────────────────────────────────────────────────

  Widget _buildSyncBar() {
    final subtext = pendingQueue == 0
        ? 'All notes synced'
        : '$pendingQueue item${pendingQueue > 1 ? 's' : ''} waiting to upload';

    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud sync',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _OutlineButton(
            icon: Icons.cloud_upload_outlined,
            label: _isSyncing ? 'Syncing…' : 'Sync now',
            onPressed: _isSyncing ? null : _manualSync,
          ),
        ],
      ),
    );
  }

  // ── Notes list ─────────────────────────────────────────────────────────────

  Widget _buildNotesList() {
    if (notes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No notes yet',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index] as Map;
        final isSaved = note['saved'] == true;
        // In a real app you'd track per-note sync state; for now assume
        // any note in the queue is unsynced.
        final isSynced = note['synced'] == true;

        return _NoteItem(
          title: note['title'] ?? '',
          isSaved: isSaved,
          isSynced: isSynced,
          onBookmarkTap: () => _toggleSaved(note),
          onDeleteTap: () => _deleteNote(note),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: Colors.grey.shade200),
        ),
        title: const Text(
          'My Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildSyncBadge(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(),
            const SizedBox(height: 12),
            _buildAddNoteCard(),
            const SizedBox(height: 12),
            _buildSyncBar(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${notes.length} notes',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildNotesList(),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlineButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final String title;
  final bool isSaved;
  final bool isSynced;
  final VoidCallback onBookmarkTap;
  final VoidCallback onDeleteTap;

  const _NoteItem({
    required this.title,
    required this.isSaved,
    required this.isSynced,
    required this.onBookmarkTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                _SyncTag(isSynced: isSynced),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onBookmarkTap,
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 18,
              color: isSaved
                  ? const Color(0xFFBA7517)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),             // ← add from here
          GestureDetector(
            onTap: onDeleteTap,
            child: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncTag extends StatelessWidget {
  final bool isSynced;
  const _SyncTag({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    final bg = isSynced
        ? const Color(0xFFD4EDDA)
        : const Color(0xFFFFF3CD);
    final fg = isSynced
        ? const Color(0xFF155724)
        : const Color(0xFF856404);
    final label = isSynced ? '✓  synced' : '⏳  pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

/// A dot that optionally pulses to indicate activity.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool animate;

  const _PulsingDot({required this.color, required this.animate});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 1, end: 0.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: widget.animate ? _opacity.value : 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}