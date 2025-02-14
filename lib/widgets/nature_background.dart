import 'dart:math';
import 'package:flutter/material.dart';

class Leaf {
  final double x;
  final double y;
  final double size;
  final double angle;
  final double speed;
  double opacity;

  Leaf({
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    required this.speed,
    this.opacity = 0.0,
  });
}

class NatureBackground extends StatefulWidget {
  final int numberOfLeaves;
  final Color primaryColor;
  final Color secondaryColor;

  const NatureBackground({
    super.key,
    this.numberOfLeaves = 15,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<NatureBackground> createState() => _NatureBackgroundState();
}

class _NatureBackgroundState extends State<NatureBackground>
    with SingleTickerProviderStateMixin {
  late List<Leaf> leaves;
  late AnimationController _controller;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeLeaves();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateLeaves();
      });
    _controller.repeat();
  }

  void _initializeLeaves() {
    leaves = List.generate(widget.numberOfLeaves, (index) {
      return Leaf(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 20 + 10,
        angle: random.nextDouble() * 2 * pi,
        speed: random.nextDouble() * 0.2 + 0.1,
        opacity: random.nextDouble() * 0.2 + 0.1,
      );
    });
  }

  void _updateLeaves() {
    setState(() {
      for (var leaf in leaves) {
        // Update opacity
        leaf.opacity += (random.nextDouble() - 0.5) * 0.1;
        if (leaf.opacity < 0.1) leaf.opacity = 0.1;
        if (leaf.opacity > 0.3) leaf.opacity = 0.3;

        // Update position - falling motion with slight horizontal movement
        double newY = leaf.y + leaf.speed * 0.02;
        double newX = leaf.x + sin(leaf.angle) * 0.005;

        // Reset position if leaf goes out of bounds
        if (newY > 1.0) {
          newY = -0.1;
          newX = random.nextDouble();
        }
        if (newX < -0.1) newX = 1.1;
        if (newX > 1.1) newX = -0.1;

        // Update the leaf
        leaves[leaves.indexOf(leaf)] = Leaf(
          x: newX,
          y: newY,
          size: leaf.size,
          angle: leaf.angle + 0.02, // Slowly rotate the leaf
          speed: leaf.speed,
          opacity: leaf.opacity,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.secondaryColor,
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: LeafPainter(
            leaves: leaves,
            color: Colors.white,
          ),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class LeafPainter extends CustomPainter {
  final List<Leaf> leaves;
  final Color color;

  LeafPainter({required this.leaves, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final leafPath = Path()
      ..moveTo(0, -10)
      ..cubicTo(-5, -5, -10, 0, -5, 5)
      ..cubicTo(-10, 10, -5, 15, 0, 10)
      ..cubicTo(5, 15, 10, 10, 5, 5)
      ..cubicTo(10, 0, 5, -5, 0, -10)
      ..close();

    for (var leaf in leaves) {
      final matrix = Matrix4.identity()
        ..translate(leaf.x * size.width, leaf.y * size.height)
        ..rotateZ(leaf.angle)
        ..scale(leaf.size / 20);

      final leafTransformed = leafPath.transform(matrix.storage);
      paint.color = color.withOpacity(leaf.opacity);
      canvas.drawPath(leafTransformed, paint);
    }
  }

  @override
  bool shouldRepaint(LeafPainter oldDelegate) => true;
}
