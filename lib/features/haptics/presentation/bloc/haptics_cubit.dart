import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/haptics_service.dart';

// State
class HapticsState extends Equatable {
  final bool isEnabled;

  const HapticsState({this.isEnabled = true});

  @override
  List<Object> get props => [isEnabled];
}

// Cubit
class HapticsCubit extends Cubit<HapticsState> {
  final HapticsService hapticsService;

  HapticsCubit(this.hapticsService) : super(const HapticsState());

  void toggleHaptics() {
    emit(HapticsState(isEnabled: !state.isEnabled));
  }

  Future<void> lightImpact() async {
    if (state.isEnabled) await hapticsService.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (state.isEnabled) await hapticsService.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (state.isEnabled) await hapticsService.heavyImpact();
  }

  Future<void> success() async {
    if (state.isEnabled) await hapticsService.success();
  }

  Future<void> error() async {
    if (state.isEnabled) await hapticsService.error();
  }
}
