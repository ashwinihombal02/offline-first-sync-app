import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const notesBox = 'notesBox';
  static const queueBox = 'queueBox';
  static const metricsBox = 'metricsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(notesBox);
    await Hive.openBox(queueBox);
    await Hive.openBox(metricsBox);
  }
}