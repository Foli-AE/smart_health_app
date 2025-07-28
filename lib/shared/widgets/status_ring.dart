import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../models/vital_signs.dart';
import 'dart:math' as math;

/// Central Status Ring - The heart of the dashboard
/// Shows overall health status with beautiful animations
class StatusRing extends StatefulWidget {
  final double healthScore;
  final HealthStatus status;
  final bool isAnimated;
  final VoidCallback? onTap;

  const StatusRing({
    super.key,
    required this.healthScore,
    required this.status,
    this.isAnimated = true,
    this.onTap,
  });

  @override
  State<StatusRing> createState() => _StatusRingState();
}

class _StatusRingState extends State<StatusRing>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Pulse animation for the ring
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Gentle rotation for visual interest
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isAnimated) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    return AppColors.getStatusColor(widget.healthScore);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppTheme.elevation3,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _rotationController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: CustomPaint(
                  painter: StatusRingPainter(
                    healthScore: widget.healthScore,
                    statusColor: _statusColor,
                    backgroundColor: AppColors.backgroundTertiary,
                  ),
                  child: Transform.rotate(
                    angle: -_rotationAnimation.value, // Counter-rotate content
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Health Score
                          Text(
                            '${widget.healthScore.toInt()}',
                            style: AppTypography.displayLarge.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          
                          // Status Label
                          Text(
                            widget.status.displayName,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Status Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.status.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ).animate().scale(
        duration: AppTheme.mediumAnimation,
        curve: AppTheme.emphasizedCurve,
      ).fadeIn(
        duration: AppTheme.longAnimation,
        curve: AppTheme.standardCurve,
      ),
    );
  }
}

/// Custom painter for the Status Ring
class StatusRingPainter extends CustomPainter {
  final double healthScore;
  final Color statusColor;
  final Color backgroundColor;

  StatusRingPainter({
    required this.healthScore,
    required this.statusColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 16.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring with gradient
    final progressPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          statusColor.withValues(alpha: 0.8),
          statusColor,
          statusColor.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Calculate sweep angle based on health score
    final sweepAngle = (healthScore / 100) * 2 * math.pi;
    const startAngle = -math.pi / 2; // Start from top

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Inner glow effect
    final glowPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // Subtle dots for visual interest
    _drawDecorationDots(canvas, center, radius + 30, statusColor);
  }

  void _drawDecorationDots(Canvas canvas, Offset center, double radius, Color color) {
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const dotCount = 8;
    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i) / dotCount;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(StatusRingPainter oldDelegate) {
    return oldDelegate.healthScore != healthScore ||
           oldDelegate.statusColor != statusColor ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Compact version of the Status Ring for smaller spaces
class CompactStatusRing extends StatelessWidget {
  final double healthScore;
  final HealthStatus status;
  final double size;

  const CompactStatusRing({
    super.key,
    required this.healthScore,
    required this.status,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(healthScore);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${healthScore.toInt()}',
              style: AppTypography.headlineSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status.displayName,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      duration: AppTheme.mediumAnimation,
      curve: AppTheme.emphasizedCurve,
    );
  }
} 