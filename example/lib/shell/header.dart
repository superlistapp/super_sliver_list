import "package:flutter/material.dart" show Colors, Icons;
import "package:pixel_snap/widgets.dart";

import "../widgets/button.dart";

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.openNavigationSidebar,
  });

  final void Function()? openNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.shade400,
            width: 1,
          ),
        ),
      ),
      child: IntrinsicHeight(
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
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SuperSliverList",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFFF84F39),
                      fontWeight: FontWeight.bold,
                    ),
                    // style: theme.textTheme.headline6!.copyWith(color: Colors.white),
                  ),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    child: LinkButton(
                      uri: Uri.parse(
                        "https://github.com/superlistapp/super_sliver_list",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
