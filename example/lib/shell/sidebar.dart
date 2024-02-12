import 'package:context_watch/context_watch.dart';
import 'package:example/shell/app_settings.dart';
import 'package:example/shell/check_box.dart';
import 'package:example/shell/example_page.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:headless_widgets/headless_widgets.dart';
import 'package:provider/provider.dart';

import 'routes.dart';

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
    final settings = context.watch<AppSettings>();
    final showSliverList = settings.showSliverList.watch(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(
          end: BorderSide(
            color: Colors.blueGrey.shade400,
            width: 1,
          ),
        ),
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...allRoutes.map(
              (route) =>
                  _NavigationButton(uri: route.fullPath, title: route.title),
            ),
            const SizedBox(
              height: 14,
            ),
            if (pageWidget != null) pageWidget,
            CheckBox(
              checked: showSliverList,
              child: const Text(
                'Compare with SliverList',
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: (value) => settings.showSliverList.value = value,
            ),
          ],
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

class _DisableIntrinsicWidth extends SingleChildRenderObjectWidget {
  const _DisableIntrinsicWidth({
    super.key,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDisableIntrinsicWidth();
  }
}

class _RenderDisableIntrinsicWidth extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) {
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return 0;
  }
}
