import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class VoiceInputButton extends StatefulWidget {
  final bool isRecording;
  final double volume; // 0.0 to 1.0
  final double size;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const VoiceInputButton({
    super.key,
    required this.isRecording,
    this.volume = 0.0,
    this.size = 64,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.isRecording ? widget.onCancel : null,
      onTapDown: (_) {
         if (!widget.isRecording) widget.onStart();
      },
      onTapUp: (_) {
         if (widget.isRecording) widget.onStop();
      },
      onTapCancel: () {
         if (widget.isRecording) widget.onStop();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Effect
          if (widget.isRecording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (widget.volume * 0.5) + (_pulseController.value * 0.2);
                return Container(
                  width: widget.size * scale,
                  height: widget.size * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          
          // Main Button
          GlassmorphicCard(
            borderRadius: widget.size / 2,
            blur: 10,
            padding: EdgeInsets.zero,
            showBorder: true,
            color: widget.isRecording 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.isRecording ? Icons.mic : Icons.mic_none,
                  color: widget.isRecording ? Colors.white : Colors.white70,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          )
              .animate(target: widget.isRecording ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
              .tint(color: Colors.redAccent.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}

class VoiceWaveform extends StatelessWidget {
  final double volume;
  final int barCount;
  final double height;
  final Color color;

  const VoiceWaveform({
    super.key, 
    required this.volume,
    this.barCount = 5, 
    this.height = 30,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barCount, (index) {
        // Simple visualizer with staggered animation
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 4,
            height: height * (0.3 + (volume * 0.7 * ((index % 2 == 0) ? 1.0 : 0.6))), 
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
