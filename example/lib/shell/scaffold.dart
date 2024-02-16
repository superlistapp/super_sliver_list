import "package:flutter/widgets.dart";

class Scaffold extends StatefulWidget {
  final Widget body;
  final Widget? drawer;

  const Scaffold({
    super.key,
    required this.body,
    this.drawer,
  });

  @override
  State<StatefulWidget> createState() => ScaffoldState();
}

class ScaffoldState extends State<Scaffold>
    with SingleTickerProviderStateMixin {
  void openDrawer() {
    if (widget.drawer != null) {
      _drawerController.forward();
    }
  }

  void closeDrawer() {
    if (widget.drawer != null) {
      _drawerController.reverse();
    }
  }

  late final AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FocusScope(
      debugLabel: "Scaffold",
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.body,
          if (widget.drawer != null) ...[
            Positioned.fill(
              child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final value = animation.value;
                    if (value == 0) {
                      return const SizedBox();
                    } else {
                      return GestureDetector(
                        onTap: closeDrawer,
                        child: Container(
                          color:
                              const Color(0x00000000).withOpacity(0.5 * value),
                        ),
                      );
                    }
                  }),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: widget.drawer,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
