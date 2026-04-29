class AppConstants {
  static const String appName = 'Offline First Notes';

  /// Hive Box Names
  static const String notesBox = 'notesBox';
  static const String queueBox = 'queueBox';
  static const String metricsBox = 'metricsBox';

  /// Sync Config
  static const int maxRetryCount = 1;
  static const int retryDelaySeconds = 2;

  /// Action Types
  static const String addNote = 'add_note';
  static const String toggleSave = 'toggle_save';

  /// Cache TTL (Bonus)
  static const int cacheTTLMinutes = 30;
}