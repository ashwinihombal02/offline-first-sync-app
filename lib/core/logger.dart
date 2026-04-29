class AppLogger {
  static void info(String message) {
    print('INFO -> $message');
  }

  static void success(String message) {
    print('SUCCESS -> $message');
  }

  static void error(String message) {
    print('ERROR -> $message');
  }

  static void queue(int size) {
    print('QUEUE SIZE -> $size');
  }

  static void retry(String message) {
    print('RETRY -> $message');
  }
}