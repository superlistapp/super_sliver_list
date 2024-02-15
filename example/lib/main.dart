import "shell/app.dart";
import "package:logging/logging.dart";
import "package:pixel_snap/widgets.dart";

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
  runApp(PixelSnapDebugBar(child: const ExampleApp()));
}
