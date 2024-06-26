import "package:context_plus/context_plus.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart"
    show Colors, Scrollbar, ScrollbarTheme, ScrollbarThemeData, Typography;
import "package:flutter/services.dart";
import "package:pixel_snap/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

import "../util/media_query.dart";
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
    return ContextPlus.root(
      child: Builder(builder: (context) {
        appSettings.bind(context, () => AppSettings());
        return WidgetsApp(
          shortcuts: _platformDefaultShortcuts,
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
        );
      }),
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
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: false,
              removeRight: false,
              removeTop: true,
              child: ColoredBox(
                color: Colors.white,
                child: widget.child,
              ),
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
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MediaQueryExt.removePaddingDirectional(
                    context: context,
                    removeTrailing: true,
                    child: Sidebar(
                      key: sidebarKey,
                      currentPageKey: currentPageKey,
                    ),
                  ),
                  MediaQueryExt.removePaddingDirectional(
                    removeLeading: true,
                    context: context,
                    child: Expanded(
                      child: ColoredBox(
                        color: Colors.white,
                        child: child,
                      ),
                    ),
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
  TargetPlatform getPlatform(BuildContext context) {
    // Cupertino scrollbar has broken overscroll, for now force macOS on
    // all platforms.
    final platform = super.getPlatform(context);
    if (platform == TargetPlatform.iOS) {
      return TargetPlatform.macOS;
    } else {
      return platform;
    }
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return Colors.black.withOpacity(0.4);
          }
          return Colors.black.withOpacity(0.1);
        }),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(platformBrightness: Brightness.light),
        child: Scrollbar(
          controller: details.controller,
          thumbVisibility: true,
          child: child,
        ),
      ),
    );
  }
}

// Override ridiculous defaults where arrow keys on web drive scrolling instead
// of focus.

Map<ShortcutActivator, Intent> get _platformDefaultShortcuts {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return _defaultShortcuts;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return _defaultAppleOsShortcuts;
  }
}

const Map<ShortcutActivator, Intent> _defaultAppleOsShortcuts =
    <ShortcutActivator, Intent>{
  // Activation
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),

  // Dismissal
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),

  // Keyboard traversal
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      DirectionalFocusIntent(TraversalDirection.right),
  SingleActivator(LogicalKeyboardKey.arrowDown):
      DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      DirectionalFocusIntent(TraversalDirection.up),

  // Scrolling
  SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
      ScrollIntent(direction: AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
      ScrollIntent(direction: AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
      ScrollIntent(direction: AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
      ScrollIntent(direction: AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.pageUp):
      ScrollIntent(direction: AxisDirection.up, type: ScrollIncrementType.page),
  SingleActivator(LogicalKeyboardKey.pageDown): ScrollIntent(
      direction: AxisDirection.down, type: ScrollIncrementType.page),
};

const Map<ShortcutActivator, Intent> _defaultShortcuts =
    <ShortcutActivator, Intent>{
  // Activation
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),

  // Dismissal
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),

  // Keyboard traversal.
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      DirectionalFocusIntent(TraversalDirection.right),
  SingleActivator(LogicalKeyboardKey.arrowDown):
      DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      DirectionalFocusIntent(TraversalDirection.up),

  // Scrolling
  SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
      ScrollIntent(direction: AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
      ScrollIntent(direction: AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
      ScrollIntent(direction: AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
      ScrollIntent(direction: AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.pageUp):
      ScrollIntent(direction: AxisDirection.up, type: ScrollIncrementType.page),
  SingleActivator(LogicalKeyboardKey.pageDown): ScrollIntent(
      direction: AxisDirection.down, type: ScrollIncrementType.page),
};
