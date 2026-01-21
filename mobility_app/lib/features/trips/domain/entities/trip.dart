import 'package:equatable/equatable.dart';

/// Status of a completed trip
enum TripStatus {
  completed,
  cancelled,
  inProgress;

  String get displayName {
    switch (this) {
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.inProgress:
        return 'In Progress';
    }
  }
}

/// Trip entity for history display
class Trip extends Equatable {
  final String id;
  final String driverName;
  final String? driverAvatarUrl;
  final String fromLocation;
  final String toLocation;
  final DateTime tripDate;
  final TripStatus status;
  final String amount;
  final String currency;
  final double? rating;

  const Trip({
    required this.id,
    required this.driverName,
    this.driverAvatarUrl,
    required this.fromLocation,
    required this.toLocation,
    required this.tripDate,
    required this.status,
    required this.amount,
    this.currency = 'RWF',
    this.rating,
  });

  /// Formatted date display
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDay = DateTime(tripDate.year, tripDate.month, tripDate.day);

    if (tripDay == today) {
      return 'Today, ${_formatTime(tripDate)}';
    } else if (tripDay == yesterday) {
      return 'Yesterday';
    } else {
      return '${_monthName(tripDate.month)} ${tripDate.day}';
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  List<Object?> get props => [id, driverName, fromLocation, toLocation, tripDate, status, amount];
}
