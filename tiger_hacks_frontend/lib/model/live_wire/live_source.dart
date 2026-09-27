import 'dart:convert';
import 'dart:math';

import 'package:tiger_hacks_frontend/util.dart';

abstract class LiveSource {
  Stream<int>? get bpSysStream;
  Stream<int>? get bpDiaStream;
  Stream<int>? get heartRateStream;
  Stream<int>? get respRateStream;
  Stream<double>? get tempStream;
  Stream<double>? get bloodOxStream;
  bool hasDevice(MeasureType measureType);
  bool isSimulated(MeasureType measureType);
}

Future<PersonalLiveSource> loadDefaultPersonalLiveSource(int userId) async {
  final devicesString = await sharedPrefs.getString(userId.toString());
  if (devicesString == null) {
    return PersonalLiveSource.fromDevices();
  }
  try {
    return PersonalLiveSource.fromJson(json.decode(devicesString));
  } on Exception {
    return PersonalLiveSource.fromDevices();
  }
}

Future<void> savePersonalLiveSource(
  int userId,
  PersonalLiveSource source,
) async {
  await sharedPrefs.setString(userId.toString(), json.encode(source.toJson()));
}

class PersonalLiveSource implements LiveSource {
  factory PersonalLiveSource.fromJson(Map? obj) {
    return PersonalLiveSource.fromDevices(
      bpSys: _deviceFromJson<int>(obj, 'bpSys'),
      bpDia: _deviceFromJson<int>(obj, 'bpDia'),
      heartRate: _deviceFromJson<int>(obj, 'heartRate'),
      respRate: _deviceFromJson<int>(obj, 'respRate'),
      temperature: _deviceFromJson<double>(obj, 'temperature'),
      bloodOx: _deviceFromJson<double>(obj, 'bloodOx'),
    );
  }

  PersonalLiveSource.fromDevices({
    Device<int>? bpSys,
    Device<int>? bpDia,
    Device<int>? heartRate,
    Device<int>? respRate,
    Device<double>? temperature,
    Device<double>? bloodOx,
  }) : _bpSys = bpSys,
       _bpDia = bpDia,
       _heartRate = heartRate,
       _respRate = respRate,
       _temperature = temperature,
       _bloodOx = bloodOx,
       _bpSysStream = bpSys?.stream,
       _bpDiaStream = bpDia?.stream,
       _heartRateStream = heartRate?.stream,
       _respRateStream = respRate?.stream,
       _tempStream = temperature?.stream,
       _bloodOxStream = bloodOx?.stream;

  final Device<int>? _bpSys;
  final Device<int>? _bpDia;
  final Device<int>? _heartRate;
  final Device<int>? _respRate;
  final Device<double>? _temperature;
  final Device<double>? _bloodOx;

  final Stream<int>? _bpSysStream;
  final Stream<int>? _bpDiaStream;
  final Stream<int>? _heartRateStream;
  final Stream<int>? _respRateStream;
  final Stream<double>? _tempStream;
  final Stream<double>? _bloodOxStream;

  Map<String, dynamic> toJson() => {
    if (_bpSys != null) 'bpSys': _bpSys.toJson(),
    if (_bpDia != null) 'bpDia': _bpDia.toJson(),
    if (_heartRate != null) 'heartRate': _heartRate.toJson(),
    if (_respRate != null) 'respRate': _respRate.toJson(),
    if (_temperature != null) 'temperature': _temperature.toJson(),
    if (_bloodOx != null) 'bloodOx': _bloodOx.toJson(),
  };

  @override
  Stream<int>? get bpSysStream => _bpSysStream;

  @override
  Stream<int>? get bpDiaStream => _bpDiaStream;

  @override
  Stream<int>? get heartRateStream => _heartRateStream;

  @override
  Stream<int>? get respRateStream => _respRateStream;

  @override
  Stream<double>? get tempStream => _tempStream;

  @override
  Stream<double>? get bloodOxStream => _bloodOxStream;

  @override
  bool hasDevice(MeasureType measureType) => switch (measureType) {
    MeasureType.bpSys => _bpSys != null,
    MeasureType.bpDia => _bpDia != null,
    MeasureType.heartRate => _heartRate != null,
    MeasureType.respRate => _respRate != null,
    MeasureType.temperature => _temperature != null,
    MeasureType.bloodOx => _bloodOx != null,
  };

  @override
  bool isSimulated(MeasureType measureType) => switch (measureType) {
    MeasureType.bpSys => _bpSys is SimulatedDevice<int>,
    MeasureType.bpDia => _bpDia is SimulatedDevice<int>,
    MeasureType.heartRate => _heartRate is SimulatedDevice<int>,
    MeasureType.respRate => _respRate is SimulatedDevice<int>,
    MeasureType.temperature => _temperature is SimulatedDevice<double>,
    MeasureType.bloodOx => _bloodOx is SimulatedDevice<double>,
  };
}

Device<T>? _deviceFromJson<T>(Map? json, String key) {
  final value = json?[key];
  if (value == null) return null;
  if (value is! Map) {
    throw FormatException('Device "$key" must be a JSON object.');
  }
  return Device<T>.fromJson(Map<String, dynamic>.from(value));
}

abstract class Device<T> {
  factory Device.fromJson(Map<String, dynamic> json) {
    final deviceType = json['deviceType'];
    final measureTypeName = json['measureType'];
    final patternName = json['pattern'];
    final intervalIndex = json['whichInterval'] ?? 0;
    if (deviceType != 'SimulatedDevice') {
      throw FormatException('Unsupported device type: $deviceType.');
    }
    if (measureTypeName is! String || patternName is! String) {
      throw const FormatException(
        'A simulated device requires measureType and pattern strings.',
      );
    }
    if (intervalIndex is! int) {
      throw const FormatException('whichInterval must be an integer.');
    }

    final measureType = MeasureType.values.byName(measureTypeName);
    final pattern = SimulationPattern.values.byName(patternName);
    if (intervalIndex < 0) {
      throw const FormatException('whichInterval cannot be negative.');
    }
    final usesDouble =
        measureType == MeasureType.temperature ||
        measureType == MeasureType.bloodOx;

    if (T == int && !usesDouble) {
      return SimulatedDevice<int>(
        initialPattern: pattern,
        measureType: measureType,
        whichInterval: intervalIndex,
      ) as Device<T>;
    }
    if (T == double && usesDouble) {
      return SimulatedDevice<double>(
        initialPattern: pattern,
        measureType: measureType,
        whichInterval: intervalIndex,
      ) as Device<T>;
    }
    throw FormatException(
      'Measure type $measureTypeName is incompatible with Device<$T>.',
    );
  }

  Stream<T> get stream;

  Map<String, dynamic> toJson();
}

enum Range { Healthy, Unhealthy, Critical }

enum SimulationPattern { Healthy, Unhealthy, Critical, Deteriorating }

enum MeasureType { bpSys, bpDia, heartRate, respRate, temperature, bloodOx }

class _ValueRange {
  const _ValueRange(this.minimum, this.maximum);

  final double minimum;
  final double maximum;

  bool contains(num value) => value >= minimum && value <= maximum;
}

const _measureRanges = <MeasureType, Map<Range, List<_ValueRange>>>{
  // Adult resting reference ranges; blood pressure is measured in mmHg.
  MeasureType.bpSys: {
    Range.Healthy: [_ValueRange(90, 119)],
    Range.Unhealthy: [_ValueRange(70, 89), _ValueRange(120, 179)],
    Range.Critical: [_ValueRange(40, 69), _ValueRange(180, 250)],
  },
  MeasureType.bpDia: {
    Range.Healthy: [_ValueRange(60, 79)],
    Range.Unhealthy: [_ValueRange(40, 59), _ValueRange(80, 119)],
    Range.Critical: [_ValueRange(20, 39), _ValueRange(120, 160)],
  },
  // Adult resting pulse, in beats per minute.
  MeasureType.heartRate: {
    Range.Healthy: [_ValueRange(60, 100)],
    Range.Unhealthy: [_ValueRange(41, 59), _ValueRange(101, 149)],
    Range.Critical: [_ValueRange(20, 40), _ValueRange(150, 220)],
  },
  // Adult resting respiratory rate, in breaths per minute.
  MeasureType.respRate: {
    Range.Healthy: [_ValueRange(12, 20)],
    Range.Unhealthy: [_ValueRange(9, 11), _ValueRange(21, 24)],
    Range.Critical: [_ValueRange(1, 8), _ValueRange(25, 60)],
  },
  // Temperature is Fahrenheit. Clinical cutoffs vary by measurement method.
  MeasureType.temperature: {
    Range.Healthy: [_ValueRange(97, 99)],
    Range.Unhealthy: [_ValueRange(95, 96.9), _ValueRange(99.1, 103.9)],
    Range.Critical: [_ValueRange(86, 94.9), _ValueRange(104, 109.4)],
  },
  // SpO2 is percent for a typical adult at sea level.
  MeasureType.bloodOx: {
    Range.Healthy: [_ValueRange(95, 100)],
    Range.Unhealthy: [_ValueRange(90, 94)],
    Range.Critical: [_ValueRange(70, 89)],
  },
};

Range rangeForValue(MeasureType measureType, num value) {
  final ranges = _measureRanges[measureType]!;
  for (final range in Range.values) {
    if (ranges[range]!.any((interval) => interval.contains(value))) {
      return range;
    }
  }
  return Range.Critical;
}

class SimulatedDevice<T> implements Device<T> {
  SimulationPattern pattern;
  final MeasureType measureType;
  final int whichInterval; // 0 or 1
  final Random _random = Random();
  late final Stream<T> _stream;

  SimulatedDevice({
    required SimulationPattern initialPattern,
    required this.measureType,
    this.whichInterval = 0,
  }) : pattern = initialPattern {
    final usesDouble =
        measureType == MeasureType.temperature ||
        measureType == MeasureType.bloodOx;
    if (usesDouble != (T == double)) {
      throw ArgumentError.value(
        T,
        'T',
        'Use double for temperature/blood oxygen and int for other measures.',
      );
    }
    _stream = createStream().asBroadcastStream();
  }

  Stream<T> createStream() async* {
    int tick = 0;
    while (true) {
      yield _generateNext(tick);
      await Future.delayed(const Duration(seconds: 3));
      tick++;
    }
  }

  T _generateNext(int tick) {
    final range = switch (pattern) {
      SimulationPattern.Healthy => Range.Healthy,
      SimulationPattern.Unhealthy => Range.Unhealthy,
      SimulationPattern.Critical => Range.Critical,
      SimulationPattern.Deteriorating => _deterioratingRange(tick),
    };
    final intervals = _measureRanges[measureType]![range]!;
    final interval = intervals[whichInterval % intervals.length];
    final value = _randomValue(interval);

    if (T == double) return value.toDouble() as T;
    return value.round() as T;
  }

  Range _deterioratingRange(int tick) {
    if (tick < 10) return Range.Healthy;
    if (tick < 20) return Range.Unhealthy;
    return Range.Critical;
  }

  num _randomValue(_ValueRange interval) {
    if (measureType == MeasureType.temperature) {
      final minimumTenth = (interval.minimum * 10).ceil();
      final maximumTenth = (interval.maximum * 10).floor();
      return (minimumTenth + _random.nextInt(maximumTenth - minimumTenth + 1)) /
          10;
    }

    final minimum = interval.minimum.ceil();
    final maximum = interval.maximum.floor();
    return minimum + _random.nextInt(maximum - minimum + 1);
  }

  @override
  Map<String, dynamic> toJson() => {
    'deviceType': 'SimulatedDevice',
    'measureType': measureType.name,
    'pattern': pattern.name,
    'whichInterval': whichInterval,
  };

  @override
  Stream<T> get stream => _stream;
}

/// -------------------

// class StreamingLiveSource implements LiveSource {};
