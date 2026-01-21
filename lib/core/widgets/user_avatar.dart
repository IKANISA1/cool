import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A user avatar widget with online indicator and fallback initials
///
/// Features:
/// - Cached network image loading
/// - Fallback to initials when no image
/// - Optional online indicator
/// - Customizable size and colors
class UserAvatar extends StatelessWidget {
  /// URL of the avatar image
  final String? imageUrl;

  /// Initials to display when no image is available
  final String initials;

  /// Size of the avatar (width and height)
  final double size;

  /// Whether to show the online indicator
  final bool isOnline;

  /// Whether to show the online indicator at all
  final bool showOnlineIndicator;

  /// Background color for initials fallback
  final Color? backgroundColor;

  /// Text color for initials
  final Color? textColor;

  /// Border width around the avatar
  final double borderWidth;

  /// Border color
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 48,
    this.isOnline = false,
    this.showOnlineIndicator = true,
    this.backgroundColor,
    this.textColor,
    this.borderWidth = 0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final txtColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Stack(
      children: [
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: borderWidth > 0
                ? Border.all(
                    color: borderColor ?? theme.colorScheme.outline,
                    width: borderWidth,
                  )
                : null,
          ),
          child: ClipOval(
            child: _buildAvatarContent(bgColor, txtColor),
          ),
        ),

        // Online indicator
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent(Color bgColor, Color txtColor) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildInitials(bgColor, txtColor),
        errorWidget: (context, url, error) => _buildInitials(bgColor, txtColor),
      );
    }
    return _buildInitials(bgColor, txtColor);
  }

  Widget _buildInitials(Color bgColor, Color txtColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: txtColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A group of overlapping avatars for showing multiple users
class AvatarGroup extends StatelessWidget {
  final List<UserAvatarData> avatars;
  final double size;
  final double overlap;
  final int maxDisplay;

  const AvatarGroup({
    super.key,
    required this.avatars,
    this.size = 40,
    this.overlap = 0.3,
    this.maxDisplay = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = avatars.length > maxDisplay ? maxDisplay : avatars.length;
    final remaining = avatars.length - displayCount;

    return SizedBox(
      height: size,
      width: size + (displayCount - 1) * size * (1 - overlap) + (remaining > 0 ? size * (1 - overlap) : 0),
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * size * (1 - overlap),
              child: UserAvatar(
                imageUrl: avatars[i].imageUrl,
                initials: avatars[i].initials,
                size: size,
                isOnline: avatars[i].isOnline,
                showOnlineIndicator: false,
                borderWidth: 2,
                borderColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayCount * size * (1 - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data class for avatar group
class UserAvatarData {
  final String? imageUrl;
  final String initials;
  final bool isOnline;

  const UserAvatarData({
    this.imageUrl,
    required this.initials,
    this.isOnline = false,
  });
}
