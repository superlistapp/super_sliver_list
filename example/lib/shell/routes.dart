import "package:flutter/material.dart";

import "../examples/item_list.dart";
import "../examples/long_document.dart";
import "example_page.dart";

class ExamplePage extends StatefulWidget {
  final String name;

  const ExamplePage({
    super.key,
    required this.name,
  });

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends ExamplePageState<ExamplePage> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.name);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget? createSidebarWidget() {
    return Text(widget.name);
  }
}

class Route {
  final String fullPath;
  final String title;
  final Widget Function(GlobalKey<ExamplePageState>) builder;

  const Route({
    required this.fullPath,
    required this.title,
    required this.builder,
  });
}

final allRoutes = [
  Route(
    fullPath: "/example/item-list",
    title: "Item List",
    builder: (key) => ItemListPage(key: key),
  ),
  Route(
    fullPath: "/example/long-document",
    title: "Long document",
    builder: (key) => LongDocumentPage(key: key),
  ),
];
