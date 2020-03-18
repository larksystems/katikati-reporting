import 'dart:html';

class Logger {
  String file;

  Logger(this.file);

  String _getPrefix() {
    var date = DateTime.now();
    return '[${file} $date]';
  }

  void log(String message) {
    window.console.log('${_getPrefix()} $message');
  }

  void warn(String message) {
    window.console.warn('${_getPrefix()} $message');
  }

  void error(String message) {
    window.console.error('${_getPrefix()} $message');
  }
}
