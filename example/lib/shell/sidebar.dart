import "package:context_watch/context_watch.dart";
import "package:flutter/material.dart" show Colors;
import "package:headless_widgets/headless_widgets.dart" as w;
import "package:pixel_snap/widgets.dart";
import "package:provider/provider.dart";

import "../util/intersperse.dart";
import "../widgets/button.dart";
import "../widgets/check_box.dart";
import "app_settings.dart";
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

  final controller = PixelSnapScrollController();

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
        color: Colors.blueGrey.shade100,
        border: BorderDirectional(
          end: BorderSide(
            color: Colors.blueGrey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: controller,
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
    required this.uri,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final selected = route?.settings.name == uri;

    return w.Button(
      onPressed: () {
        Navigator.pushNamed(context, uri);
      },
      child: Text(title),
      builder: (context, state, child) {
        final background =
            switch ((selected, state.focused, state.hovered, state.pressed)) {
          (true, _, _, _) => Colors.blue.shade400,
          (_, _, _, true) => Colors.blue.shade400.withOpacity(0.3),
          (_, _, true, _) => Colors.blue.shade400.withOpacity(0.2),
          (_, _, _, _) => Colors.transparent,
        };
        final textColor = switch ((selected, state.hovered)) {
          (true, _) => Colors.white,
          (false, _) => Colors.black,
        };
        return Container(
          decoration: BoxDecoration(
            color: background,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: DefaultTextStyle(
            style: TextStyle(
              color: textColor,
            ),
            child: child!,
          ),
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
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections
            .intersperse(
              const SizedBox(
                height: 8,
              ),
            )
            .toList(growable: false),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12).copyWith(bottom: 0),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children.intersperse(const SizedBox(height: 10)),
              ],
            ),
          ),
        ],
      ),
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
    return SidebarSection(title: const Text("Options"), children: [
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          const Text(
            "Precalculate Extents",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(
            height: 6,
          ),
          SegmentedButton(
            selectedIndex: precomputeExtentPolicy.index,
            onSelected: (selected) {
              settings.precomputeExtentPolicy.value =
                  PrecomputeExtentPolicy.values[selected];
            },
            children: PrecomputeExtentPolicy.values
                .map(
                  (policy) => Text(policy.displayName),
                )
                .toList(),
          )
        ],
      ),
    ]);
  }
}
