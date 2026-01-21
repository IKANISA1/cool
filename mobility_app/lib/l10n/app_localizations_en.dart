// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mobility';

  @override
  String get welcome => 'Welcome';

  @override
  String get continueButton => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get phoneAuthTitle => 'Enter your phone number';

  @override
  String get phoneAuthSubtitle => 'We\'ll send you a verification code';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get sendCode => 'Send Code';

  @override
  String get otpTitle => 'Verification';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the code sent to $phone';
  }

  @override
  String get verifyCode => 'Verify';

  @override
  String get resendCode => 'Resend Code';

  @override
  String codeExpires(int seconds) {
    return 'Code expires in $seconds seconds';
  }

  @override
  String get discoveryTitle => 'Nearby';

  @override
  String get findDrivers => 'Find Drivers';

  @override
  String get findPassengers => 'Find Passengers';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String get noUsersNearby => 'No users nearby';

  @override
  String get adjustRadius => 'Try adjusting your search radius';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get role => 'Role';

  @override
  String get roleDriver => 'Driver';

  @override
  String get rolePassenger => 'Passenger';

  @override
  String get roleBoth => 'Both';

  @override
  String get language => 'Language';

  @override
  String get rating => 'Rating';

  @override
  String get verified => 'Verified';

  @override
  String get vehicleTitle => 'My Vehicles';

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get vehicleCategory => 'Category';

  @override
  String get vehiclePlate => 'Plate Number';

  @override
  String get vehicleCapacity => 'Capacity';

  @override
  String get vehicleCategoryMoto => 'Motorcycle';

  @override
  String get vehicleCategoryCab => 'Taxi Cab';

  @override
  String get vehicleCategoryLiffan => 'Liffan';

  @override
  String get vehicleCategoryTruck => 'Truck';

  @override
  String get vehicleCategoryRent => 'Rental';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get incomingRequests => 'Incoming';

  @override
  String get outgoingRequests => 'Outgoing';

  @override
  String get pendingRequests => 'Pending';

  @override
  String get acceptRequest => 'Accept';

  @override
  String get declineRequest => 'Decline';

  @override
  String get requestExpired => 'Request expired';

  @override
  String get noRequests => 'No pending requests';

  @override
  String get noIncomingRequests => 'No incoming requests';

  @override
  String get noOutgoingRequests => 'No outgoing requests';

  @override
  String get incomingRequestsHint =>
      'Requests from other users will appear here';

  @override
  String get outgoingRequestsHint => 'Requests you send will appear here';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get requestStatusAccepted => 'Accepted';

  @override
  String get requestStatusDenied => 'Denied';

  @override
  String get requestStatusExpired => 'Expired';

  @override
  String get requestStatusCancelled => 'Cancelled';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get scheduleTitle => 'Schedule Trip';

  @override
  String get scheduleOffer => 'Offer a Ride';

  @override
  String get scheduleRequest => 'Request a Ride';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get when => 'When';

  @override
  String get seats => 'Seats';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get notes => 'Notes';

  @override
  String get scheduleTrip => 'Schedule';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get aiAssistantHint => 'How can I help you today?';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get notifications => 'Notifications';

  @override
  String get language_settings => 'Language';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get logout => 'Log Out';

  @override
  String get version => 'Version';

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get locationPermissionMessage =>
      'Location is required to find nearby users';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String lastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get onlineNow => 'Online now';
}
