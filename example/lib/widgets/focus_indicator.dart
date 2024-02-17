import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";

class FocusIndicator extends StatelessWidget {
  const FocusIndicator({
    super.key,
    required this.focused,
    required this.child,
    this.readius = 8.0,
  });

  final bool focused;
  final Widget child;
  final double readius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: focused ? 1.0 : 0.0),
      curve: Curves.easeOutQuad,
      duration: focused ? const Duration(milliseconds: 300) : Duration.zero,
      builder: (context, focus, child) {
        return CustomPaint(
          painter: _FocusPainter(
            pixelSnap: PixelSnap.of(context),
            radius: readius,
            focus: focus,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _FocusPainter extends CustomPainter {
  final double focus;
  final double radius;
  final PixelSnap pixelSnap;

  _FocusPainter({
    required this.pixelSnap,
    required this.focus,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (focus > 0) {
      final opacity = focus;

      final paint = Paint()
        ..color = Colors.deepOrange.shade200.withOpacity(opacity);

      final radius = Radius.circular(this.radius).pixelSnap(pixelSnap);
      var rect = (Offset.zero & size).pixelSnap(pixelSnap).inflate(2);

      canvas.translate(rect.width / 2.0, rect.height / 2.0);
      rect = rect.translate(-rect.width / 2.0, -rect.height / 2.0);

      canvas.scale(
        1.0 + 14.0 / size.width * (1.0 - focus),
        1.0 + 14.0 / size.height * (1.0 - focus),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusPainter oldDelegate) {
    return focus != oldDelegate.focus;
  }
}
