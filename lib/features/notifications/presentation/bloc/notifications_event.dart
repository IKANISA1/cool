import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications
class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

/// Mark a single notification as read
class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllAsRead extends NotificationsEvent {
  const MarkAllAsRead();
}

/// Refresh notifications
class RefreshNotifications extends NotificationsEvent {
  const RefreshNotifications();
}
