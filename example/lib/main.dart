import "package:example/shell/app.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";

void main() {
  Logger.root.onRecord.listen((record) {
    print("${record.level.name}: ${record.message}");
  });
  hierarchicalLoggingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  // WidgetsBinding.instance.addTimingsCallback((timings) {
  //     print('Timings $timings');
  // });
  Logger("SuperSliverList").level = Level.FINER;
  runApp(const ExampleApp());
}
