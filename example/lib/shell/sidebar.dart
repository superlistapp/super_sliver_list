import "package:context_watch/context_watch.dart";
import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";
import "package:headless_widgets/headless_widgets.dart";
import "package:provider/provider.dart";

import "../util/intersperse.dart";
import "app_settings.dart";
import "buttons.dart";
import "check_box.dart";
import "example_page.dart";
import "routes.dart";

class Sidebar extends StatefulWidget {
  final void Function()? onCloseDrawer;
  final GlobalKey<ExamplePageState> currentPageKey;

  const Sidebar({
    super.key,
    required this.currentPageKey,
    this.onCloseDrawer,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _rebuildScheduled = false;

  @override
  Widget build(BuildContext context) {
    final pageWidget =
        widget.currentPageKey.currentState?.createSidebarWidget.call();
    if (!_rebuildScheduled) {
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          (context as Element).markNeedsBuild();
        }
      });
    } else {
      _rebuildScheduled = false;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(
          end: BorderSide(
            color: Colors.blueGrey.shade400,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...allRoutes.map(
                  (route) => _NavigationButton(
                      uri: route.fullPath, title: route.title),
                ),
                const SizedBox(
                  height: 14,
                ),
                if (pageWidget != null) pageWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String uri;
  final String title;

  const _NavigationButton({
    super.key,
    required this.uri,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final selected = route?.settings.name == uri;

    return Button(
      onPressed: () {
        Navigator.pushNamed(context, uri);
      },
      child: Text(title),
      builder: (context, state, child) {
        final background =
            switch ((selected, state.focused, state.hovered, state.pressed)) {
          (true, _, _, _) => Colors.blue,
          (_, _, true, _) => Colors.blue.shade100,
          (_, _, _, _) => Colors.transparent,
        };
        return Container(
          decoration: BoxDecoration(
            color: background,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: child!,
        );
      },
    );
  }
}

class SidebarOptions extends StatelessWidget {
  const SidebarOptions({
    super.key,
    required this.sections,
  });

  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections
          .intersperse(
            const SizedBox(
              height: 8,
            ),
          )
          .toList(growable: false),
    );
  }
}

class SidebarSection extends StatelessWidget {
  const SidebarSection({
    super.key,
    required this.title,
    required this.children,
  });

  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: BorderDirectional(
              bottom: BorderSide(
                color: Colors.white,
                width: 1,
              ),
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.bold,
            ),
            child: title,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children.intersperse(const SizedBox(height: 8)),
            ],
          ),
        ),
      ],
    );
  }
}

class AppSettingsWidget extends StatelessWidget {
  const AppSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final showSliverList = settings.showSliverList.watch(context);
    final precomputeExtentPolicy =
        settings.precomputeExtentPolicy.watch(context);
    return SidebarSection(title: Text("Settings"), children: [
      CheckBox(
        checked: showSliverList,
        child: const Text(
          "Compare with SliverList",
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        onChanged: (value) => settings.showSliverList.value = value,
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Precompute extents"),
          SegmentedButton(
            selectedIndex: precomputeExtentPolicy.index,
            onSelected: (selected) {
              settings.precomputeExtentPolicy.value =
                  PrecomputeExtentPolicy.values[selected];
            },
            children: const [
              Text("None"),
              Text("All"),
              Text("Automatic"),
            ],
          )
        ],
      ),
    ]);
  }
}
