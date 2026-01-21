import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// Notifications bloc for managing notification state
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading(
      notifications: state.notifications,
      unreadCount: state.unreadCount,
    ));

    try {
      // TODO: Replace with actual data source when backend is ready
      final notifications = _getMockNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError(
        message: e.toString(),
        notifications: state.notifications,
        unreadCount: state.unreadCount,
      ));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(NotificationsLoaded(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final updatedNotifications = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    emit(NotificationsLoaded(
      notifications: updatedNotifications,
      unreadCount: 0,
    ));
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    add(const LoadNotifications());
  }

  /// Mock notifications for demo - replace with real data source
  List<AppNotification> _getMockNotifications() {
    final now = DateTime.now();
    
    return [
      AppNotification(
        id: '1',
        type: NotificationType.request,
        title: 'New Ride Request',
        message: 'Marie Claire sent you a ride request',
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: NotificationType.accepted,
        title: 'Request Accepted',
        message: 'Jean Paul accepted your request',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        type: NotificationType.payment,
        title: 'Payment Received',
        message: 'You received 5,000 RWF',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        type: NotificationType.system,
        title: 'Welcome to RideLink!',
        message: 'Complete your profile to start connecting',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }
}
