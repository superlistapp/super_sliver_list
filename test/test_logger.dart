import "dart:async";

import "package:logging/logging.dart";

class _TestLogger {
  void log(LogRecord r) {
    _entries.add(r);
    if (r.level >= Level.WARNING) {
      _printMessage(r);
    }
  }

  void clear() {
    _entries.clear();
  }

  void printLog() {
    Zone.current.print("Complete log from failed test:");
    for (final e in _entries) {
      _printMessage(e);
    }
  }

  void _printMessage(LogRecord e) {
    Zone.current.print("${e.level.name.padRight(7)} ${e.message}");
  }

  final _entries = <LogRecord>[];
}

final _TestLogger _testLogger = _TestLogger();

/// Initializes logger that captures all log messages from tests without printing them.
void initTestLogging() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord rec) {
    _testLogger.log(rec);
  });
}

void resetTestLog() {
  _testLogger.clear();
}

/// Prints all log messages captured from tests.
void printTestLog() {
  _testLogger.printLog();
}
