import 'dart:async';
import 'package:flutter/material.dart';

/// A circular countdown timer widget
///
/// Features:
/// - Animated circular progress
/// - Color transitions as time decreases
/// - Optional pulse animation for urgency
/// - Customizable size and colors
class CountdownTimer extends StatefulWidget {
  /// Total duration in seconds
  final int totalSeconds;

  /// Remaining seconds (for controlled mode)
  final int? remainingSeconds;

  /// Callback when timer completes
  final VoidCallback? onComplete;

  /// Callback on each tick with remaining seconds
  final ValueChanged<int>? onTick;

  /// Size of the circular timer
  final double size;

  /// Stroke width of the progress arc
  final double strokeWidth;

  /// Background color of the progress circle
  final Color? backgroundColor;

  /// Whether to auto-start the timer
  final bool autoStart;

  /// Whether to show pulse animation when time is low
  final bool showUrgencyPulse;

  /// Threshold in seconds for urgency animation
  final int urgencyThreshold;

  const CountdownTimer({
    super.key,
    required this.totalSeconds,
    this.remainingSeconds,
    this.onComplete,
    this.onTick,
    this.size = 120,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.autoStart = true,
    this.showUrgencyPulse = true,
    this.urgencyThreshold = 10,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  Timer? _timer;
  late int _remainingSeconds;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds ?? widget.totalSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.autoStart && widget.remainingSeconds == null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingSeconds != null &&
        widget.remainingSeconds != _remainingSeconds) {
      setState(() {
        _remainingSeconds = widget.remainingSeconds!;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _isRunning = true;
    _progressController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        widget.onTick?.call(_remainingSeconds);

        // Start pulse animation when time is low
        if (widget.showUrgencyPulse &&
            _remainingSeconds <= widget.urgencyThreshold &&
            !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _timer?.cancel();
        _isRunning = false;
        widget.onComplete?.call();
      }
    });
  }

  void start() {
    if (!_isRunning) {
      _startTimer();
    }
  }

  void pause() {
    _timer?.cancel();
    _progressController.stop();
    _isRunning = false;
  }

  void reset() {
    _timer?.cancel();
    _progressController.reset();
    _pulseController.reset();
    setState(() {
      _remainingSeconds = widget.totalSeconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _remainingSeconds / widget.totalSeconds;
    final color = _getColorForProgress(progress, theme);
    final bgColor = widget.backgroundColor ??
        theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.showUrgencyPulse &&
                _remainingSeconds <= widget.urgencyThreshold
            ? 1.0 + _pulseController.value * 0.05
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: widget.strokeWidth,
                color: bgColor,
              ),
            ),

            // Progress circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: widget.strokeWidth,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),

            // Time display
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_remainingSeconds),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForProgress(double progress, ThemeData theme) {
    if (progress > 0.5) {
      return theme.colorScheme.primary;
    } else if (progress > 0.25) {
      return Colors.orange;
    } else {
      return theme.colorScheme.error;
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return seconds.toString();
    } else {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }
}

/// A linear countdown progress bar
class CountdownProgressBar extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final double height;

  const CountdownProgressBar({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = remainingSeconds / totalSeconds;
    final color = _getColorForProgress(progress, theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${remainingSeconds}s remaining',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getColorForProgress(double progress, ThemeData theme) {
    if (progress > 0.5) {
      return theme.colorScheme.primary;
    } else if (progress > 0.25) {
      return Colors.orange;
    } else {
      return theme.colorScheme.error;
    }
  }
}
