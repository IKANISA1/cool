// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String get appTitle => 'Mobility';

  @override
  String get welcome => 'Murakaza neza';

  @override
  String get continueButton => 'Komeza';

  @override
  String get cancel => 'Hagarika';

  @override
  String get save => 'Bika';

  @override
  String get delete => 'Siba';

  @override
  String get edit => 'Hindura';

  @override
  String get loading => 'Gutegereza...';

  @override
  String get retry => 'Ongera ugerageze';

  @override
  String get error => 'Ikosa';

  @override
  String get success => 'Byagenze neza';

  @override
  String get phoneAuthTitle => 'Shyiramo nimero ya terefone yawe';

  @override
  String get phoneAuthSubtitle => 'Tuzakohereza kode yo kwemeza';

  @override
  String get phoneNumberLabel => 'Nimero ya terefone';

  @override
  String get sendCode => 'Ohereza kode';

  @override
  String get otpTitle => 'Kwemeza';

  @override
  String otpSubtitle(String phone) {
    return 'Shyiramo kode yoherejwe kuri $phone';
  }

  @override
  String get verifyCode => 'Emeza';

  @override
  String get resendCode => 'Ongera wohereze kode';

  @override
  String codeExpires(int seconds) {
    return 'Kode irangira mu masegonda $seconds';
  }

  @override
  String get discoveryTitle => 'Hafi yawe';

  @override
  String get findDrivers => 'Shakira abashoferi';

  @override
  String get findPassengers => 'Shakira abagenzi';

  @override
  String get searchRadius => 'Urugero rwo gushakira';

  @override
  String get noUsersNearby => 'Nta mukoresha uri hafi';

  @override
  String get adjustRadius => 'Gerageza guhindura urugero rwo gushakira';

  @override
  String get profileTitle => 'Umwirondoro';

  @override
  String get editProfile => 'Hindura umwirondoro';

  @override
  String get name => 'Izina';

  @override
  String get role => 'Uruhare';

  @override
  String get roleDriver => 'Umushoferi';

  @override
  String get rolePassenger => 'Umugenzi';

  @override
  String get roleBoth => 'Byombi';

  @override
  String get language => 'Ururimi';

  @override
  String get rating => 'Amanota';

  @override
  String get verified => 'Byemejwe';

  @override
  String get vehicleTitle => 'Imodoka zanjye';

  @override
  String get addVehicle => 'Ongeraho imodoka';

  @override
  String get vehicleCategory => 'Ubwoko';

  @override
  String get vehiclePlate => 'Nimero ya plaki';

  @override
  String get vehicleCapacity => 'Uburemere';

  @override
  String get vehicleCategoryMoto => 'Moto';

  @override
  String get vehicleCategoryCab => 'Tagisi';

  @override
  String get vehicleCategoryLiffan => 'Liffan';

  @override
  String get vehicleCategoryTruck => 'Ikamyo';

  @override
  String get vehicleCategoryRent => 'Gukodesha';

  @override
  String get requestsTitle => 'Ibisabwa';

  @override
  String get incomingRequests => 'Byaje';

  @override
  String get outgoingRequests => 'Byoherejwe';

  @override
  String get pendingRequests => 'Bitegereje';

  @override
  String get acceptRequest => 'Emera';

  @override
  String get declineRequest => 'Anga';

  @override
  String get requestExpired => 'Icyifuzo cyarangiye';

  @override
  String get noRequests => 'Nta cyifuzo gitegereje';

  @override
  String get noIncomingRequests => 'Nta cyifuzo cyaje';

  @override
  String get noOutgoingRequests => 'Nta cyifuzo cyoherejwe';

  @override
  String get incomingRequestsHint =>
      'Ibisabwa by\'abandi bakoresha bizagaragara hano';

  @override
  String get outgoingRequestsHint => 'Ibisabwa wohereza bizagaragara hano';

  @override
  String get requestStatusPending => 'Gitegereje';

  @override
  String get requestStatusAccepted => 'Cyemewe';

  @override
  String get requestStatusDenied => 'Cyangiwe';

  @override
  String get requestStatusExpired => 'Cyarangiye';

  @override
  String get requestStatusCancelled => 'Cyahagaritswe';

  @override
  String get justNow => 'Ubu nyine';

  @override
  String minutesAgo(int minutes) {
    return 'hashize ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'hashize ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'hashize ${days}d';
  }

  @override
  String get scheduleTitle => 'Teganya urugendo';

  @override
  String get scheduleOffer => 'Tanga urugendo';

  @override
  String get scheduleRequest => 'Saba urugendo';

  @override
  String get from => 'Kuva';

  @override
  String get to => 'Kuri';

  @override
  String get when => 'Ryari';

  @override
  String get seats => 'Intebe';

  @override
  String get vehicleType => 'Ubwoko bw\'imodoka';

  @override
  String get notes => 'Ibitekerezo';

  @override
  String get scheduleTrip => 'Teganya';

  @override
  String get aiAssistantTitle => 'Umufasha AI';

  @override
  String get aiAssistantHint => 'Nakugufasha nte?';

  @override
  String get typeMessage => 'Andika ubutumwa...';

  @override
  String get settingsTitle => 'Igenamiterere';

  @override
  String get darkMode => 'Uburyo bwijimye';

  @override
  String get notifications => 'Imenyesha';

  @override
  String get language_settings => 'Ururimi';

  @override
  String get privacyPolicy => 'Politiki y\'ubuzima bwite';

  @override
  String get termsOfService => 'Amategeko y\'ikoreshwa';

  @override
  String get logout => 'Sohoka';

  @override
  String get version => 'Verisiyo';

  @override
  String get locationPermissionTitle => 'Uruhushya rw\'aho uri';

  @override
  String get locationPermissionMessage =>
      'Aho uri birakenewe kugira ngo tubone abakoresha bari hafi';

  @override
  String get grantPermission => 'Tanga uruhushya';

  @override
  String distanceAway(String distance) {
    return 'kuri $distance';
  }

  @override
  String lastSeen(String time) {
    return 'Yabonwe hashize $time';
  }

  @override
  String get onlineNow => 'Ari ku murongo';
}
