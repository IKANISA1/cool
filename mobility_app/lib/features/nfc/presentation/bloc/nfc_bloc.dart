import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../data/services/nfc_service.dart';

// ════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════

abstract class NFCEvent extends Equatable {
  const NFCEvent();
  @override
  List<Object?> get props => [];
}

/// Start NFC scanning session
class StartNFCScan extends NFCEvent {}

/// Stop NFC scanning session
class StopNFCScan extends NFCEvent {}

/// Start NFC write operation (Android only)
class WriteNFCTag extends NFCEvent {
  final String data;
  final String mimeType;

  const WriteNFCTag({
    required this.data,
    this.mimeType = 'text/plain',
  });

  @override
  List<Object?> get props => [data, mimeType];
}

/// Process NFC payment
class ProcessNFCPayment extends NFCEvent {
  final double amount;
  final String currency;

  const ProcessNFCPayment({
    required this.amount,
    this.currency = 'RWF',
  });

  @override
  List<Object?> get props => [amount, currency];
}

/// Check NFC availability
class CheckNFCAvailability extends NFCEvent {}

// Internal events
class _NFCDataEvent extends NFCEvent {
  final NfcTag tag;
  const _NFCDataEvent(this.tag);
  @override
  List<Object?> get props => [tag];
}

class _NFCReadResultEvent extends NFCEvent {
  final NFCReadResult result;
  const _NFCReadResultEvent(this.result);
  @override
  List<Object?> get props => [result];
}

class _NFCWriteResultEvent extends NFCEvent {
  final NFCWriteResult result;
  const _NFCWriteResultEvent(this.result);
  @override
  List<Object?> get props => [result];
}

class _NFCPaymentResultEvent extends NFCEvent {
  final PaymentResult result;
  const _NFCPaymentResultEvent(this.result);
  @override
  List<Object?> get props => [result];
}

/// Verify driver badge via NFC
class VerifyDriverBadge extends NFCEvent {}

/// Read loyalty/rewards card via NFC
class ReadLoyaltyCard extends NFCEvent {}

/// Open device NFC settings
class OpenNFCSettings extends NFCEvent {}

/// Write trip verification data (Android only)
class WriteTripData extends NFCEvent {
  final String tripId;
  final String passengerId;
  final String driverId;

  const WriteTripData({
    required this.tripId,
    required this.passengerId,
    required this.driverId,
  });

  @override
  List<Object?> get props => [tripId, passengerId, driverId];
}

// Internal events for driver/loyalty results
class _DriverVerificationResultEvent extends NFCEvent {
  final DriverVerificationResult result;
  const _DriverVerificationResultEvent(this.result);
  @override
  List<Object?> get props => [result];
}

class _LoyaltyCardResultEvent extends NFCEvent {
  final LoyaltyCardResult result;
  const _LoyaltyCardResultEvent(this.result);
  @override
  List<Object?> get props => [result];
}

class _NFCErrorEvent extends NFCEvent {
  final String error;
  const _NFCErrorEvent(this.error);
  @override
  List<Object?> get props => [error];
}

// ════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════

abstract class NFCState extends Equatable {
  const NFCState();
  @override
  List<Object?> get props => [];
}

/// Initial state
class NFCInitial extends NFCState {}

/// Checking NFC availability
class NFCCheckingAvailability extends NFCState {}

/// NFC is not available on device
class NFCUnavailable extends NFCState {
  final String message;
  const NFCUnavailable([this.message = 'NFC is not available on this device']);
  @override
  List<Object?> get props => [message];
}

/// NFC is available and ready
class NFCAvailable extends NFCState {
  final bool canWrite;
  const NFCAvailable({this.canWrite = false});
  @override
  List<Object?> get props => [canWrite];
}

/// Scanning for NFC tag
class NFCScanning extends NFCState {}

/// Tag discovered (legacy compatibility)
class NFCScanned extends NFCState {
  final NfcTag tag;
  const NFCScanned(this.tag);
  @override
  List<Object?> get props => [tag];
}

/// Tag read successful with parsed data
class NFCReadSuccess extends NFCState {
  final NFCReadResult result;
  const NFCReadSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

/// Writing to NFC tag
class NFCWriting extends NFCState {
  final String data;
  const NFCWriting(this.data);
  @override
  List<Object?> get props => [data];
}

/// Write successful
class NFCWriteSuccess extends NFCState {
  const NFCWriteSuccess();
}

/// Processing payment
class NFCPaymentProcessing extends NFCState {
  final double amount;
  final String currency;
  const NFCPaymentProcessing({required this.amount, required this.currency});
  @override
  List<Object?> get props => [amount, currency];
}

/// Payment successful
class NFCPaymentSuccess extends NFCState {
  final PaymentResult result;
  const NFCPaymentSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

/// Driver verification in progress
class NFCVerifyingDriver extends NFCState {
  const NFCVerifyingDriver();
}

/// Driver verification complete
class NFCDriverVerified extends NFCState {
  final DriverVerificationResult result;
  const NFCDriverVerified(this.result);
  @override
  List<Object?> get props => [result];
}

/// Reading loyalty card
class NFCReadingLoyaltyCard extends NFCState {
  const NFCReadingLoyaltyCard();
}

/// Loyalty card read complete
class NFCLoyaltyCardRead extends NFCState {
  final LoyaltyCardResult result;
  const NFCLoyaltyCardRead(this.result);
  @override
  List<Object?> get props => [result];
}

/// Opening NFC settings
class NFCOpeningSettings extends NFCState {
  const NFCOpeningSettings();
}

/// Error state
class NFCError extends NFCState {
  final String message;
  const NFCError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════

class NFCBloc extends Bloc<NFCEvent, NFCState> {
  final NFCService nfcService;

  NFCBloc(this.nfcService) : super(NFCInitial()) {
    // Public events
    on<CheckNFCAvailability>(_onCheckAvailability);
    on<StartNFCScan>(_onStartScan);
    on<StopNFCScan>(_onStopScan);
    on<WriteNFCTag>(_onWriteTag);
    on<ProcessNFCPayment>(_onProcessPayment);
    
    // New domain-specific events
    on<VerifyDriverBadge>(_onVerifyDriver);
    on<ReadLoyaltyCard>(_onReadLoyaltyCard);
    on<WriteTripData>(_onWriteTripData);
    on<OpenNFCSettings>(_onOpenSettings);
    
    // Internal events
    on<_NFCDataEvent>((event, emit) => emit(NFCScanned(event.tag)));
    on<_NFCReadResultEvent>((event, emit) => emit(NFCReadSuccess(event.result)));
    on<_NFCWriteResultEvent>(_onWriteResult);
    on<_NFCPaymentResultEvent>(_onPaymentResult);
    on<_DriverVerificationResultEvent>((event, emit) => emit(NFCDriverVerified(event.result)));
    on<_LoyaltyCardResultEvent>((event, emit) => emit(NFCLoyaltyCardRead(event.result)));
    on<_NFCErrorEvent>((event, emit) => emit(NFCError(event.error)));
  }

  /// Check if NFC is available on device
  Future<void> _onCheckAvailability(
    CheckNFCAvailability event,
    Emitter<NFCState> emit,
  ) async {
    emit(NFCCheckingAvailability());
    
    final isAvailable = await nfcService.isNfcAvailable;
    
    if (isAvailable) {
      // Android supports writing, iOS does not
      emit(NFCAvailable(canWrite: Platform.isAndroid));
    } else {
      emit(const NFCUnavailable());
    }
  }

  /// Start NFC tag scanning
  Future<void> _onStartScan(
    StartNFCScan event,
    Emitter<NFCState> emit,
  ) async {
    emit(NFCScanning());

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    // Use the new readNFCTag for structured results
    final result = await nfcService.readNFCTag();
    
    if (result.success) {
      add(_NFCReadResultEvent(result));
    } else {
      add(_NFCErrorEvent(result.errorMessage ?? 'Failed to read NFC tag'));
    }
  }

  /// Stop NFC scanning
  Future<void> _onStopScan(
    StopNFCScan event,
    Emitter<NFCState> emit,
  ) async {
    await nfcService.stopSession();
    emit(NFCInitial());
  }

  /// Write data to NFC tag
  Future<void> _onWriteTag(
    WriteNFCTag event,
    Emitter<NFCState> emit,
  ) async {
    // Platform check
    if (!Platform.isAndroid) {
      emit(const NFCError(
        'NFC writing is only supported on Android. '
        'iOS restricts NFC writing for third-party apps.',
      ));
      return;
    }

    emit(NFCWriting(event.data));

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    final result = await nfcService.writeNFCTag(
      data: event.data,
      mimeType: event.mimeType,
    );

    add(_NFCWriteResultEvent(result));
  }

  void _onWriteResult(
    _NFCWriteResultEvent event,
    Emitter<NFCState> emit,
  ) {
    if (event.result.success) {
      emit(const NFCWriteSuccess());
    } else {
      emit(NFCError(event.result.errorMessage ?? 'Write failed'));
    }
  }

  /// Process NFC payment
  Future<void> _onProcessPayment(
    ProcessNFCPayment event,
    Emitter<NFCState> emit,
  ) async {
    emit(NFCPaymentProcessing(
      amount: event.amount,
      currency: event.currency,
    ));

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    final result = await nfcService.processNFCPayment(
      amount: event.amount,
      currency: event.currency,
    );

    add(_NFCPaymentResultEvent(result));
  }

  void _onPaymentResult(
    _NFCPaymentResultEvent event,
    Emitter<NFCState> emit,
  ) {
    if (event.result.success) {
      emit(NFCPaymentSuccess(event.result));
    } else {
      emit(NFCError(event.result.message));
    }
  }

  /// Handle driver badge verification
  Future<void> _onVerifyDriver(
    VerifyDriverBadge event,
    Emitter<NFCState> emit,
  ) async {
    emit(const NFCVerifyingDriver());

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    final result = await nfcService.verifyDriverBadge();
    add(_DriverVerificationResultEvent(result));
  }

  /// Handle loyalty card reading
  Future<void> _onReadLoyaltyCard(
    ReadLoyaltyCard event,
    Emitter<NFCState> emit,
  ) async {
    emit(const NFCReadingLoyaltyCard());

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    final result = await nfcService.readLoyaltyCard();
    add(_LoyaltyCardResultEvent(result));
  }

  /// Handle trip data writing
  Future<void> _onWriteTripData(
    WriteTripData event,
    Emitter<NFCState> emit,
  ) async {
    if (!Platform.isAndroid) {
      emit(const NFCError(
        'NFC writing is only supported on Android. '
        'iOS restricts NFC writing for third-party apps.',
      ));
      return;
    }

    emit(NFCWriting('Trip: ${event.tripId}'));

    if (!await nfcService.isNfcAvailable) {
      emit(const NFCError('NFC is not available on this device'));
      return;
    }

    final result = await nfcService.writeTripData(
      tripId: event.tripId,
      passengerId: event.passengerId,
      driverId: event.driverId,
    );

    if (result.success) {
      emit(const NFCWriteSuccess());
    } else {
      emit(NFCError(result.errorMessage ?? 'Failed to write trip data'));
    }
  }

  /// Handle opening NFC settings
  Future<void> _onOpenSettings(
    OpenNFCSettings event,
    Emitter<NFCState> emit,
  ) async {
    emit(const NFCOpeningSettings());
    
    try {
      await nfcService.openNFCSettings();
      // Return to initial state after settings opened
      emit(NFCInitial());
    } catch (e) {
      emit(NFCError('Could not open NFC settings: $e'));
    }
  }

  @override
  Future<void> close() {
    nfcService.stopSession();
    return super.close();
  }
}
