import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_collect_driver/providers/cargo_provider.dart';

void main() {
  test('CargoNotifier updates thresholds and clamps', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cargoProvider.notifier);
    notifier.reset(limitKg: 1000);

    notifier.addBin(500);
    expect(container.read(cargoProvider).utilisationPct, 50);
    expect(container.read(cargoProvider).isWarning, false);

    notifier.addBin(300);
    expect(container.read(cargoProvider).isWarning, true);
    expect(container.read(cargoProvider).isNearingLimit, false);

    notifier.addBin(150);
    expect(container.read(cargoProvider).isNearingLimit, true);

    notifier.addBin(100);
    expect(container.read(cargoProvider).isAtLimit, true);

    notifier.removeBin(2000);
    expect(container.read(cargoProvider).currentKg, 0);
  });
}
