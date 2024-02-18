import "package:flutter/widgets.dart";

// ignore: avoid_classes_with_only_static_members
class MediaQueryExt {
  static MediaQuery removePaddingDirectional({
    Key? key,
    required BuildContext context,
    bool removeLeading = false,
    bool removeTop = false,
    bool removeTrailing = false,
    bool removeBottom = false,
    required Widget child,
  }) {
    final direction = Directionality.of(context);
    return MediaQuery.removePadding(
      key: key,
      removeLeft:
          direction == TextDirection.ltr ? removeLeading : removeTrailing,
      removeRight:
          direction == TextDirection.ltr ? removeTrailing : removeLeading,
      removeTop: removeTop,
      removeBottom: removeBottom,
      context: context,
      child: child,
    );
  }
}
