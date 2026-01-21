import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationsState extends Equatable {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading({
    super.notifications,
    super.unreadCount,
  });
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required super.notifications,
    required super.unreadCount,
  });
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError({
    required this.message,
    super.notifications,
    super.unreadCount,
  });

  @override
  List<Object?> get props => [message, notifications, unreadCount];
}
