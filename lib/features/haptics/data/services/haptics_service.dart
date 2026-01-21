import 'package:vibration/vibration.dart';

class HapticsService {
  Future<bool> get hasVibrator async => await Vibration.hasVibrator();
  Future<bool> get hasAmplitudeControl async => await Vibration.hasAmplitudeControl();
  Future<bool> get hasCustomVibrationsSupport async => await Vibration.hasCustomVibrationsSupport();

  Future<void> vibrate({int duration = 500, int amplitude = -1}) async {
    if (await hasVibrator) {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    }
  }

  Future<void> lightImpact() async {
    if (await hasVibrator) {
      Vibration.vibrate(duration: 50, amplitude: 30);
    }
  }

  Future<void> mediumImpact() async {
    if (await hasVibrator) {
      Vibration.vibrate(duration: 100, amplitude: 70);
    }
  }

  Future<void> heavyImpact() async {
    if (await hasVibrator) {
      Vibration.vibrate(duration: 150, amplitude: 255);
    }
  }

  Future<void> success() async {
    if (await hasVibrator) {
      // Review: Simple success pattern
       Vibration.vibrate(pattern: [0, 50, 100, 50]);
    }
  }

  Future<void> error() async {
    if (await hasVibrator) {
      // Review: Simple error pattern
       Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
    }
  }
}
