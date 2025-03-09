import 'dart:math';

import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  final Widget child;
  const WaveBackground({super.key, required this.child});

  @override
  _WaveBackgroundState createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            CustomPaint(
              painter: WavePainter(_animation.value),
              size: MediaQuery.of(context).size,
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

/// A custom painter to draw a dynamic sine-wave background.
class WavePainter extends CustomPainter {
  final double waveOffset;
  WavePainter(this.waveOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 105, 65, 198)
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Set a base height (80% down the screen)
    const double baseHeightFactor = 0.8;
    final double baseHeight = size.height * baseHeightFactor;
    path.moveTo(0, baseHeight);

    // Draw a sine wave across the canvas width.
    for (double x = 0; x <= size.width; x++) {
      double y = baseHeight + 20 * sin((x / size.width * 2 * pi) + waveOffset);
      path.lineTo(x, y);
    }

    // Complete the path to cover the bottom of the screen.
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset;
  }
}
