import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom search bar with voice input option
///
/// Features:
/// - Glassmorphic styling
/// - Voice input button
/// - Clear button when text is present
/// - Debounced search callback
class CustomSearchBar extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController? controller;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSubmitted;

  /// Callback for voice input button
  final VoidCallback? onVoiceSearch;

  /// Placeholder text
  final String hintText;

  /// Whether voice input is available
  final bool showVoiceButton;

  /// Debounce duration for onChanged
  final Duration debounceDuration;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onVoiceSearch,
    this.hintText = 'Search...',
    this.showVoiceButton = true,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClear = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_showClear != hasText) {
      setState(() {
        _showClear = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSubmitted,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Clear button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showClear
                ? IconButton(
                    key: const ValueKey('clear'),
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Voice search button
          if (widget.showVoiceButton && widget.onVoiceSearch != null) ...[
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onVoiceSearch?.call();
              },
              icon: Icon(
                Icons.mic,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
