import "package:flutter/material.dart" show Icons, Colors;
import "package:pixel_snap/widgets.dart";

import "buttons.dart";

class Header extends StatelessWidget {
  const Header({
    Key? key,
    this.openNavigationSidebar,
  }) : super(key: key);

  final void Function()? openNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.shade400,
            width: 1,
          ),
        ),
      ),
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
