import "package:flutter/material.dart" show Colors;
import "package:flutter/widgets.dart";

class Theme {
  final Decoration headerDecoration;

  Theme({required this.headerDecoration});

  static Theme defaultTheme() {
    return Theme(
      headerDecoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.shade400,
            width: 1,
          ),
        ),
      ),
    );
  }
}
