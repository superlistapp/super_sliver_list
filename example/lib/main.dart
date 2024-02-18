import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:pixel_snap/widgets.dart";

import "shell/app.dart";

void main() {
  Logger.root.onRecord.listen((record) {
    debugPrint("${record.level.name}: ${record.message}");
  });
  hierarchicalLoggingEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Logger("SuperSliver").level = Level.FINER;

  // Right now the debug bar doesn't work nicely with safe area so
  // only enable it on desktop platform.
  Widget app = const ExampleApp();
  if (defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android) {
    app = PixelSnapDebugBar(child: app);
  }
  runApp(app);
}
