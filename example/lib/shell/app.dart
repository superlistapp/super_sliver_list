import "package:context_watch/context_watch.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart"
    show
        Colors,
        MaterialState,
        MaterialStateProperty,
        Scrollbar,
        ScrollbarTheme,
        ScrollbarThemeData,
        Typography;
import "package:flutter/widgets.dart";
import "package:provider/provider.dart";
import "package:super_sliver_list/super_sliver_list.dart";

import "app_settings.dart";
import "example_page.dart";
import "header.dart";
import "routes.dart";
import "scaffold.dart";
import "sidebar.dart";

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<StatefulWidget> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final GlobalKey<ExamplePageState> _currentPageKey =
      GlobalKey<ExamplePageState>();

  final _shellKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ContextWatchRoot(
      child: Provider(
        create: (_) => AppSettings(),
        child: WidgetsApp(
          color: const Color(0xFF000000),
          routes: {
            // Why is this necessary if there is initial route?
            "/": (context) => const SizedBox.shrink(),
            for (final route in allRoutes)
              route.fullPath: (context) => route.builder(_currentPageKey),
          },
          initialRoute: allRoutes.first.fullPath,
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              settings: settings,
              maintainState: false,
              allowSnapshotting: false,
              pageBuilder: (context, _, __) {
                return ShellWidget(
                  key: _shellKey,
                  currentPageKey: _currentPageKey,
                  child: builder(context),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ShellWidget extends StatefulWidget {
  final Widget child;

  const ShellWidget({
    super.key,
    required this.child,
    required this.currentPageKey,
  });

  final GlobalKey<ExamplePageState> currentPageKey;

  @override
  State<ShellWidget> createState() => _ShellWidgetState();
}

class _ShellWidgetState extends State<ShellWidget> {
  final sidebarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _ScrollBehavior(),
      child: ThemeScaffold(
        child: LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth < 700
              ? _NarrowApp(
                  currentPageKey: widget.currentPageKey,
                  sidebarKey: sidebarKey,
                  child: widget.child,
                )
              : _WideApp(
                  currentPageKey: widget.currentPageKey,
                  sidebarKey: sidebarKey,
                  child: widget.child,
                );
        }),
      ),
    );
  }
}

class _NarrowApp extends StatefulWidget {
  const _NarrowApp({
    required this.child,
    required this.currentPageKey,
    required this.sidebarKey,
  });

  final Widget child;
  final GlobalKey<ExamplePageState> currentPageKey;
  final Key sidebarKey;

  @override
  State<_NarrowApp> createState() => _NarrowAppState();
}

class _NarrowAppState extends State<_NarrowApp> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(
        key: widget.sidebarKey,
        currentPageKey: widget.currentPageKey,
        onCloseDrawer: () => _scaffoldKey.currentState!.closeDrawer(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Header(
            openNavigationSidebar: () =>
                _scaffoldKey.currentState!.openDrawer(),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideApp extends StatelessWidget {
  const _WideApp({
    required this.child,
    required this.currentPageKey,
    required this.sidebarKey,
  });

  final Widget child;
  final GlobalKey<ExamplePageState> currentPageKey;
  final Key sidebarKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Sidebar(
                  key: sidebarKey,
                  currentPageKey: currentPageKey,
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeScaffold extends StatelessWidget {
  final Widget child;

  const ThemeScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Typography.material2018(platform: defaultTargetPlatform);
    return DefaultTextStyle(
      style: typography.englishLike.bodyMedium!.copyWith(color: Colors.black),
      child: child,
    );
  }
}

class _ScrollBehavior extends ScrollBehavior {
  const _ScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return SuperRangeMaintainingScrollPhysics(
        parent: super.getScrollPhysics(context));
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered) ||
              states.contains(MaterialState.dragged)) {
            return Colors.black.withOpacity(0.4);
          }
          return Colors.black.withOpacity(0.1);
        }),
      ),
      child: Scrollbar(
        controller: details.controller,
        thumbVisibility: true,
        child: child,
      ),
    );
  }
}
