import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';

void main() {
  test('simulated device settings survive JSON round trip', () {
    final device = SimulatedDevice<int>(
      initialPattern: SimulationPattern.Unhealthy,
      measureType: MeasureType.bpSys,
      whichInterval: 1,
    );

    final json =
        jsonDecode(jsonEncode(device.toJson())) as Map<String, dynamic>;
    final restored = Device<int>.fromJson(json) as SimulatedDevice<int>;

    expect(json, {
      'deviceType': 'SimulatedDevice',
      'measureType': 'bpSys',
      'pattern': 'Unhealthy',
      'whichInterval': 1,
    });
    expect(restored.measureType, MeasureType.bpSys);
    expect(restored.pattern, SimulationPattern.Unhealthy);
    expect(restored.whichInterval, 1);
  });

  test(
    'personal source serializes configured devices and round trips',
    () async {
      final source = PersonalLiveSource.fromDevices(
        bpSys: SimulatedDevice<int>(
          initialPattern: SimulationPattern.Healthy,
          measureType: MeasureType.bpSys,
        ),
        temperature: SimulatedDevice<double>(
          initialPattern: SimulationPattern.Critical,
          measureType: MeasureType.temperature,
          whichInterval: 1,
        ),
      );

      final json =
          jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
      final restored = PersonalLiveSource.fromJson(json);
      final restoredJson =
          jsonDecode(jsonEncode(restored.toJson())) as Map<String, dynamic>;

      expect(json.keys.toSet(), {'bpSys', 'temperature'});
      expect(restoredJson, json);
      await source.dispose();
      await restored.dispose();
    },
  );

  test('personal source reports which measures are simulated', () async {
    final source = PersonalLiveSource.fromDevices(
      bpSys: SimulatedDevice<int>(
        initialPattern: SimulationPattern.Healthy,
        measureType: MeasureType.bpSys,
      ),
      bpDia: SimulatedDevice<int>(
        initialPattern: SimulationPattern.Healthy,
        measureType: MeasureType.bpDia,
      ),
      heartRate: SimulatedDevice<int>(
        initialPattern: SimulationPattern.Healthy,
        measureType: MeasureType.heartRate,
      ),
    );

    expect(source.isSimulated(MeasureType.bpSys), isTrue);
    expect(source.isSimulated(MeasureType.bpDia), isTrue);
    expect(source.isSimulated(MeasureType.heartRate), isTrue);
    expect(source.isSimulated(MeasureType.respRate), isFalse);
    await source.dispose();
  });

  test('personal source captures latest streamed values', () async {
    final source = PersonalLiveSource.fromDevices(
      heartRate: SimulatedDevice<int>(
        initialPattern: SimulationPattern.Healthy,
        measureType: MeasureType.heartRate,
      ),
    );
    final firstReading = Completer<int>();
    final subscription = source.heartRateStream!.listen(firstReading.complete);

    final reading = await firstReading.future;
    expect(source.latestValues, {MeasureType.heartRate: reading});
    await subscription.cancel();
    await source.dispose();
  });

  test('critical readings identify low and high values', () {
    expect(rangeForValue(MeasureType.bpSys, 69), Range.Critical);
    expect(
      criticalDirectionForValue(MeasureType.bpSys, 69),
      CriticalDirection.low,
    );
    expect(rangeForValue(MeasureType.bpSys, 180), Range.Critical);
    expect(
      criticalDirectionForValue(MeasureType.bpSys, 180),
      CriticalDirection.high,
    );
  });

  test('simulated stream supports live view and snapshot listeners', () async {
    final device = SimulatedDevice<int>(
      initialPattern: SimulationPattern.Healthy,
      measureType: MeasureType.heartRate,
    );
    final firstReading = Completer<int>();
    final secondReading = Completer<int>();
    final firstSubscription = device.stream.listen(firstReading.complete);
    final secondSubscription = device.stream.listen(secondReading.complete);

    expect(await firstReading.future, inInclusiveRange(60, 100));
    expect(await secondReading.future, inInclusiveRange(60, 100));
    await firstSubscription.cancel();
    await secondSubscription.cancel();
  });
}
