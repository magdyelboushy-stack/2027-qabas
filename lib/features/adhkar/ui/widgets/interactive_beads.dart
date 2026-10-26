import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractiveBeads extends StatefulWidget {
  final int count;
  final int target;
  final VoidCallback onIncrement;
  final bool isDark;

  const InteractiveBeads({
    super.key,
    required this.count,
    required this.target,
    required this.onIncrement,
    required this.isDark,
  });

  @override
  State<InteractiveBeads> createState() => _InteractiveBeadsState();
}

class _InteractiveBeadsState extends State<InteractiveBeads>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _moveAnimation;

  // Physics parameters
  final int _visibleBeads = 8;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.count < widget.target) {
      widget.onIncrement();
      _animController.forward(from: 0).then((_) {
        // Animation completes seamlessly
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Path (String)
          CustomPaint(
            size: const Size(double.infinity, 150),
            painter: _StringPainter(
              isDark: widget.isDark,
            ),
          ),

          // 2. The Beads
          SizedBox(
            height: 150,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _moveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _BeadsPainter(
                    offset: _moveAnimation.value,
                    visibleBeads: _visibleBeads,
                    isDark: widget.isDark,
                    finished: widget.count >= widget.target,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  final bool isDark;
  _StringPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width / 2,
        size.height * 0.2, // Control point (peak)
        size.width,
        size.height * 0.7 // End point
        );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeadsPainter extends CustomPainter {
  final double offset;
  final int visibleBeads;
  final bool isDark;
  final bool finished;

  _BeadsPainter({
    required this.offset,
    required this.visibleBeads,
    required this.isDark,
    required this.finished,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the path again to calculate positions
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.2, size.width, size.height * 0.7);

    // Get path metrics to move beads along it
    final metrics = path.computeMetrics().first;
    final length = metrics.length;

    // Bead styling
    final beadRadius = size.width / (visibleBeads * 1.8);
    final beadColor = finished
        ? const Color(0xFF4CAF50) // Green when done
        : (isDark
            ? const Color(0xFF00C853)
            : const Color(0xFF009688)); // Emerald/Teal

    // Draw beads
    // We draw extra beads to simulate infinite scroll
    for (int i = -1; i < visibleBeads + 2; i++) {
      // Calculate normalized position (0.0 to 1.0)
      // i + offset makes them move
      double t = (i + offset) / (visibleBeads - 1);

      // Clamp or Loop?
      // We want them to slide.
      // If we simply map t to the path length:

      if (t < -0.1 || t > 1.1) continue; // Optimization

      final tangent = metrics.getTangentForOffset(t * length);
      if (tangent == null) continue;

      final center = tangent.position;

      // Draw Bead (Sphere effect)
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            beadColor.withOpacity(0.9),
            beadColor.withBlue(50).withOpacity(1.0), // Darker edge
          ],
          center: Alignment.topLeft,
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: center, radius: beadRadius));

      // Shadow
      canvas.drawCircle(
          center.translate(0, 5),
          beadRadius,
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      // Body
      canvas.drawCircle(center, beadRadius, paint);

      // Specular highlight (Shininess)
      canvas.drawCircle(center.translate(-beadRadius * 0.3, -beadRadius * 0.3),
          beadRadius * 0.3, Paint()..color = Colors.white.withOpacity(0.4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
