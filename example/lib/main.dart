import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Flutter Demo',
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  final _cachedTitles = <int, String>{};

  String _getTitle(int index) {
    return _cachedTitles.putIfAbsent(index, () {
      final length = Object.hash(index, null) % 28 + 2;
      return lorem(paragraphs: 1, words: length);
    });
  }

  final _cachedContent = <int, String>{};

  String _getContent(int index) {
    return _cachedContent.putIfAbsent(index, () {
      final length = (Object.hash(index, null) % 20 * 10) + 2;
      return lorem(paragraphs: 1, words: length);
    });
  }

  int get _childCount => 6000;

  @override
  Widget build(BuildContext context) {
    final sliverDelegate = SliverChildBuilderDelegate(
      (context, index) => ItemWidget(
          index: index, title: _getTitle(index), content: _getContent(index)),
      childCount: _childCount,
    );
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                    child: SectionTitle(title: Text('SuperSliverList'))),
                SuperSliverList(delegate: sliverDelegate),
                SliverToBoxAdapter(
                  child: Container(height: 2, color: Colors.red),
                ),
              ],
            ),
          ),
          VerticalDivider(
            color: Colors.blueGrey.shade200,
            width: 1,
            thickness: 1,
          ),
          Expanded(
            child: Container(
              color: Colors.blueGrey.shade50,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                      child: SectionTitle(title: Text('SliverList'))),
                  SliverList(delegate: sliverDelegate),
                  SliverToBoxAdapter(
                    child: Container(height: 2, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.index,
    required this.title,
    required this.content,
  });

  final int index;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$index: $title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(content),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.red,
      child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: title),
    );
  }
}
