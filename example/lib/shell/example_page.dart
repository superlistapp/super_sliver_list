import "package:flutter/widgets.dart";

abstract class ExamplePageState<T extends StatefulWidget> extends State<T> {
  Widget? createSidebarWidget();
}
