// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mobilité';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get continueButton => 'Continuer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get phoneAuthTitle => 'Entrez votre numéro de téléphone';

  @override
  String get phoneAuthSubtitle => 'Nous vous enverrons un code de vérification';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get otpTitle => 'Vérification';

  @override
  String otpSubtitle(String phone) {
    return 'Entrez le code envoyé à $phone';
  }

  @override
  String get verifyCode => 'Vérifier';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String codeExpires(int seconds) {
    return 'Le code expire dans $seconds secondes';
  }

  @override
  String get discoveryTitle => 'À proximité';

  @override
  String get findDrivers => 'Trouver des conducteurs';

  @override
  String get findPassengers => 'Trouver des passagers';

  @override
  String get searchRadius => 'Rayon de recherche';

  @override
  String get noUsersNearby => 'Aucun utilisateur à proximité';

  @override
  String get adjustRadius => 'Essayez d\'ajuster votre rayon de recherche';

  @override
  String get profileTitle => 'Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get name => 'Nom';

  @override
  String get role => 'Rôle';

  @override
  String get roleDriver => 'Conducteur';

  @override
  String get rolePassenger => 'Passager';

  @override
  String get roleBoth => 'Les deux';

  @override
  String get language => 'Langue';

  @override
  String get rating => 'Évaluation';

  @override
  String get verified => 'Vérifié';

  @override
  String get vehicleTitle => 'Mes véhicules';

  @override
  String get addVehicle => 'Ajouter un véhicule';

  @override
  String get vehicleCategory => 'Catégorie';

  @override
  String get vehiclePlate => 'Numéro de plaque';

  @override
  String get vehicleCapacity => 'Capacité';

  @override
  String get vehicleCategoryMoto => 'Moto';

  @override
  String get vehicleCategoryCab => 'Taxi';

  @override
  String get vehicleCategoryLiffan => 'Liffan';

  @override
  String get vehicleCategoryTruck => 'Camion';

  @override
  String get vehicleCategoryRent => 'Location';

  @override
  String get requestsTitle => 'Demandes';

  @override
  String get incomingRequests => 'Reçues';

  @override
  String get outgoingRequests => 'Envoyées';

  @override
  String get pendingRequests => 'En attente';

  @override
  String get acceptRequest => 'Accepter';

  @override
  String get declineRequest => 'Refuser';

  @override
  String get requestExpired => 'Demande expirée';

  @override
  String get noRequests => 'Aucune demande en attente';

  @override
  String get noIncomingRequests => 'Aucune demande reçue';

  @override
  String get noOutgoingRequests => 'Aucune demande envoyée';

  @override
  String get incomingRequestsHint =>
      'Les demandes d\'autres utilisateurs apparaîtront ici';

  @override
  String get outgoingRequestsHint =>
      'Les demandes que vous envoyez apparaîtront ici';

  @override
  String get requestStatusPending => 'En attente';

  @override
  String get requestStatusAccepted => 'Acceptée';

  @override
  String get requestStatusDenied => 'Refusée';

  @override
  String get requestStatusExpired => 'Expirée';

  @override
  String get requestStatusCancelled => 'Annulée';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'il y a ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get scheduleTitle => 'Planifier un trajet';

  @override
  String get scheduleOffer => 'Proposer un trajet';

  @override
  String get scheduleRequest => 'Demander un trajet';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get when => 'Quand';

  @override
  String get seats => 'Places';

  @override
  String get vehicleType => 'Type de véhicule';

  @override
  String get notes => 'Notes';

  @override
  String get scheduleTrip => 'Planifier';

  @override
  String get aiAssistantTitle => 'Assistant IA';

  @override
  String get aiAssistantHint => 'Comment puis-je vous aider ?';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get notifications => 'Notifications';

  @override
  String get language_settings => 'Langue';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get logout => 'Déconnexion';

  @override
  String get version => 'Version';

  @override
  String get locationPermissionTitle => 'Permission de localisation';

  @override
  String get locationPermissionMessage =>
      'La localisation est requise pour trouver les utilisateurs à proximité';

  @override
  String get grantPermission => 'Accorder la permission';

  @override
  String distanceAway(String distance) {
    return 'à $distance';
  }

  @override
  String lastSeen(String time) {
    return 'Vu il y a $time';
  }

  @override
  String get onlineNow => 'En ligne';
}
