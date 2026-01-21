import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Performance monitoring and optimization utilities
class PerformanceUtils {
  static final _log = Logger('Performance');

  /// Initialize performance monitoring
  static void init() {
    if (kDebugMode) {
      // Enable timeline events in debug mode
      debugPrintRebuildDirtyWidgets = false;
    }

    _log.info('Performance monitoring initialized');
  }

  /// Log a performance metric
  static void logMetric(String name, Duration duration) {
    _log.info('$name: ${duration.inMilliseconds}ms');
  }

  /// Measure execution time of a function
  static Future<T> measure<T>(String name, Future<T> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      logMetric(name, stopwatch.elapsed);
    }
  }

  /// Measure sync execution time
  static T measureSync<T>(String name, T Function() fn) {
    final stopwatch = Stopwatch()..start();
    try {
      return fn();
    } finally {
      stopwatch.stop();
      logMetric(name, stopwatch.elapsed);
    }
  }
}

/// Optimized image loading with caching
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
    );
  }
}

/// Debounced callback utility
class Debouncer {
  final Duration delay;
  VoidCallback? _action;
  bool _isRunning = false;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _action = action;
    if (!_isRunning) {
      _isRunning = true;
      Future.delayed(delay, () {
        _action?.call();
        _isRunning = false;
      });
    }
  }

  void cancel() {
    _action = null;
  }
}

/// Throttled callback utility
class Throttler {
  final Duration interval;
  DateTime? _lastExecution;

  Throttler({this.interval = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastExecution == null ||
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      action();
    }
  }
}

/// Memory-efficient list builder for large datasets
class EfficientListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? separator;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const EfficientListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: separator != null ? items.length * 2 - 1 : items.length,
      itemBuilder: (context, index) {
        if (separator != null && index.isOdd) {
          return separator!;
        }
        final itemIndex = separator != null ? index ~/ 2 : index;
        return itemBuilder(context, items[itemIndex], itemIndex);
      },
      // Performance optimizations
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }
}
