import "package:flutter/material.dart" show Icons, Colors;
import "package:flutter/widgets.dart";
import "package:provider/provider.dart";

import "buttons.dart";
import "theme.dart";

class Header extends StatelessWidget {
  const Header({
    Key? key,
    this.openNavigationSidebar,
  }) : super(key: key);

  final void Function()? openNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<Theme>();
    return Container(
      height: 50,
      decoration: theme.headerDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (openNavigationSidebar != null) ...[
            AspectRatio(
              aspectRatio: 1.0,
              child: FlatButton(
                onPressed: openNavigationSidebar,
                child: const Icon(Icons.menu),
              ),
            ),
            const Spacer(),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                "SuperSliverList",
                style: TextStyle(fontSize: 16),
                // style: theme.textTheme.headline6!.copyWith(color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
