import 'package:flutter_riverpod/flutter_riverpod.dart';

class CargoState {
  final double currentKg;
  final double limitKg;

  const CargoState({
    this.currentKg = 0.0,
    this.limitKg = 2000.0,
  });

  double get utilisationPct => limitKg > 0 ? (currentKg / limitKg) * 100 : 0;
  bool get isNearingLimit => utilisationPct > 90;
  bool get isAtLimit => currentKg >= limitKg;
  bool get isWarning => utilisationPct > 70;

  CargoState copyWith({double? currentKg, double? limitKg}) {
    return CargoState(
      currentKg: currentKg ?? this.currentKg,
      limitKg: limitKg ?? this.limitKg,
    );
  }
}

class CargoNotifier extends Notifier<CargoState> {
  @override
  CargoState build() => const CargoState();

  void reset({double limitKg = 2000.0}) {
    state = CargoState(currentKg: 0, limitKg: limitKg);
  }

  void setLimit(double limitKg) {
    state = state.copyWith(limitKg: limitKg);
  }

  void addBin(double estimatedKg) {
    state = state.copyWith(currentKg: state.currentKg + estimatedKg);
  }

  void removeBin(double estimatedKg) {
    final newKg = (state.currentKg - estimatedKg).clamp(0.0, double.infinity);
    state = state.copyWith(currentKg: newKg);
  }

  void setFromActual(double actualKg) {
    state = state.copyWith(currentKg: actualKg);
  }
}

final cargoProvider = NotifierProvider<CargoNotifier, CargoState>(
  CargoNotifier.new,
);
