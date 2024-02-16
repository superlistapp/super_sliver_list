import "package:logging/logging.dart";
import "package:pixel_snap/widgets.dart";

import "shell/app.dart";

void main() {
  Logger.root.onRecord.listen((record) {
    debugPrint("${record.level.name}: ${record.message}");
  });
  hierarchicalLoggingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Logger("SuperSliverList").level = Level.FINER;
  runApp(const PixelSnapDebugBar(child: ExampleApp()));
}
