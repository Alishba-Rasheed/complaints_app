import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A premium stylish clock widget with analog and digital display
class ClockWidget extends StatefulWidget {
  final bool showAnalog;
  final bool showDate;
  final double size;
  
  const ClockWidget({
    super.key,
    this.showAnalog = true,
    this.showDate = true,
    this.size = 200,
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> with TickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF1F5F9),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAnalog) _buildAnalogClock(isDark),
          if (widget.showAnalog) const SizedBox(height: 16),
          _buildDigitalClock(theme),
          if (widget.showDate) ...[
            const SizedBox(height: 8),
            _buildDateDisplay(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalogClock(bool isDark) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _AnalogClockPainter(
          time: _now,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildDigitalClock(ThemeData theme) {
    final timeFormat = DateFormat('HH:mm:ss');
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(
                alpha: 0.3 + (_pulseController.value * 0.2),
              ),
              width: 2,
            ),
          ),
          child: Text(
            timeFormat.format(_now),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateDisplay(ThemeData theme) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    return Text(
      dateFormat.format(_now),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        letterSpacing: 1,
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final bool isDark;

  _AnalogClockPainter({required this.time, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer ring with gradient
    final outerGradient = SweepGradient(
      colors: [
        const Color(0xFF6366F1),
        const Color(0xFF8B5CF6),
        const Color(0xFFA78BFA),
        const Color(0xFF6366F1),
      ],
    );
    
    final outerPaint = Paint()
      ..shader = outerGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius - 2, outerPaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius - 8, innerPaint);

    // Draw hour markers
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMainMarker = i % 3 == 0;
      final markerLength = isMainMarker ? 12.0 : 6.0;
      final markerWidth = isMainMarker ? 3.0 : 1.5;
      
      final startRadius = radius - 18;
      final endRadius = startRadius - markerLength;
      
      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );
      
      final markerPaint = Paint()
        ..color = isDark ? Colors.white70 : Colors.black87
        ..strokeWidth = markerWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(start, end, markerPaint);
    }

    // Draw hour hand
    _drawHand(
      canvas,
      center,
      radius * 0.45,
      (time.hour % 12 + time.minute / 60) * 30 - 90,
      6,
      const Color(0xFF6366F1),
    );

    // Draw minute hand
    _drawHand(
      canvas,
      center,
      radius * 0.65,
      (time.minute + time.second / 60) * 6 - 90,
      4,
      const Color(0xFF8B5CF6),
    );

    // Draw second hand
    _drawHand(
      canvas,
      center,
      radius * 0.75,
      time.second * 6 - 90,
      2,
      const Color(0xFFEF4444),
    );

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, centerDotPaint);
    
    final innerDotPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 3, innerDotPaint);
  }

  void _drawHand(Canvas canvas, Offset center, double length, double angle, double width, Color color) {
    final radians = angle * math.pi / 180;
    final end = Offset(
      center.dx + length * math.cos(radians),
      center.dy + length * math.sin(radians),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return time.second != oldDelegate.time.second;
  }
}

/// Compact clock widget for headers
class CompactClockWidget extends StatefulWidget {
  const CompactClockWidget({super.key});

  @override
  State<CompactClockWidget> createState() => _CompactClockWidgetState();
}

class _CompactClockWidgetState extends State<CompactClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            timeFormat.format(_now),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}