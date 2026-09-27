import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/views/components/live_view.dart';

enum _SetupMeasure { bloodPressure, heartRate, respRate, temperature, bloodOx }

enum _SimulationChoice {
  healthy('Healthy', SimulationPattern.Healthy, 0),
  unhealthyLow('Unhealthy (too low)', SimulationPattern.Unhealthy, 0),
  unhealthyHigh('Unhealthy (too high)', SimulationPattern.Unhealthy, 1),
  criticalLow('Critical (too low)', SimulationPattern.Critical, 0),
  criticalHigh('Critical (too high)', SimulationPattern.Critical, 1),
  deteriorating('Deteriorating', SimulationPattern.Deteriorating, 0);

  const _SimulationChoice(this.label, this.pattern, this.whichInterval);

  final String label;
  final SimulationPattern pattern;
  final int whichInterval;
}

const _measureDetails = [
  (measure: MeasureType.bpSys, label: 'Blood pressure systolic', unit: 'mmHg'),
  (measure: MeasureType.bpDia, label: 'Blood pressure diastolic', unit: 'mmHg'),
  (measure: MeasureType.heartRate, label: 'Heart rate', unit: 'bpm'),
  (
    measure: MeasureType.respRate,
    label: 'Respiratory rate',
    unit: 'breaths/min',
  ),
  (measure: MeasureType.temperature, label: 'Temperature', unit: '°F'),
  (measure: MeasureType.bloodOx, label: 'Blood oxygen', unit: '%'),
];

class PersonalHomePage extends StatefulWidget {
  const PersonalHomePage({
    super.key,
    required this.liveSource,
    required this.onLiveSourceChanged,
  });

  final PersonalLiveSource liveSource;
  final ValueChanged<PersonalLiveSource> onLiveSourceChanged;

  @override
  State<StatefulWidget> createState() {
    return _PersonalHomePageState();
  }
}

class _PersonalHomePageState extends State<PersonalHomePage> {
  late final int? _userId;
  final Map<MeasureType, num> _latestValues = {};
  final List<StreamSubscription<dynamic>> _liveSubscriptions = [];
  int _sourceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _userId = context.read<GlobalState>().user?.id;
    _watchLiveSource(widget.liveSource);
  }

  @override
  void didUpdateWidget(covariant PersonalHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveSource != widget.liveSource) {
      _watchLiveSource(widget.liveSource);
    }
  }

  void _watchLiveSource(PersonalLiveSource liveSource) {
    final generation = ++_sourceGeneration;
    for (final subscription in _liveSubscriptions) {
      unawaited(subscription.cancel());
    }
    _liveSubscriptions.clear();
    _latestValues.clear();

    void watch<T extends num>(MeasureType measure, Stream<T>? stream) {
      if (stream == null) return;
      _liveSubscriptions.add(
        stream.listen((value) {
          if (!mounted || generation != _sourceGeneration) return;
          setState(() => _latestValues[measure] = value);
        }),
      );
    }

    watch(MeasureType.bpSys, liveSource.bpSysStream);
    watch(MeasureType.bpDia, liveSource.bpDiaStream);
    watch(MeasureType.heartRate, liveSource.heartRateStream);
    watch(MeasureType.respRate, liveSource.respRateStream);
    watch(MeasureType.temperature, liveSource.tempStream);
    watch(MeasureType.bloodOx, liveSource.bloodOxStream);
  }

  @override
  void dispose() {
    _sourceGeneration++;
    for (final subscription in _liveSubscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext bc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LiveView(title: 'Live View:', liveSource: widget.liveSource),
        Container(height: 16.0),
        Row(
          spacing: 8.0,
          children: [
            ElevatedButton(
              onPressed: _startRecord,
              child: Row(
                children: [Icon(Icons.save), Text(" Record Measures")],
              ),
            ),
            ElevatedButton(
              onPressed: _setupDevice,
              child: Row(children: [Icon(Icons.add), Text(" Setup Device")]),
            ),
          ],
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     Expanded(child: _buildSummariesTile()),
        //     Expanded(child: _buildShareTile()),
        //   ],
        // ),
      ],
    );
  }

  Future<void> _setupDevice() async {
    final setup =
        await showDialog<({_SetupMeasure measure, _SimulationChoice pattern})>(
          context: context,
          builder: (dialogContext) {
            var selectedMeasure = _SetupMeasure.heartRate;
            var selectedPattern = _SimulationChoice.healthy;

            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text('Set up device'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: 'simulated',
                        decoration: const InputDecoration(
                          labelText: 'Device type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'simulated',
                            child: Text('Simulated'),
                          ),
                          DropdownMenuItem(
                            value: 'bluetooth',
                            enabled: false,
                            child: Text('Bluetooth (coming soon)'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<_SetupMeasure>(
                        initialValue: selectedMeasure,
                        decoration: const InputDecoration(labelText: 'Measure'),
                        items: _SetupMeasure.values
                            .map(
                              (measure) => DropdownMenuItem(
                                value: measure,
                                child: Text(_measureLabel(measure)),
                              ),
                            )
                            .toList(),
                        onChanged: (measureType) {
                          if (measureType == null) return;
                          setDialogState(() => selectedMeasure = measureType);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedMeasure == _SetupMeasure.bloodPressure)
                        const Text(
                          'This sets up both systolic and diastolic readings.',
                        ),
                      if (selectedMeasure == _SetupMeasure.bloodPressure)
                        const SizedBox(height: 16),
                      DropdownButtonFormField<_SimulationChoice>(
                        initialValue: selectedPattern,
                        decoration: const InputDecoration(
                          labelText: 'Simulation pattern',
                        ),
                        items: _SimulationChoice.values
                            .map(
                              (pattern) => DropdownMenuItem(
                                value: pattern,
                                child: Text(pattern.label),
                              ),
                            )
                            .toList(),
                        onChanged: (pattern) {
                          if (pattern == null) return;
                          setDialogState(() => selectedPattern = pattern);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, (
                      measure: selectedMeasure,
                      pattern: selectedPattern,
                    )),
                    child: const Text('Add device'),
                  ),
                ],
              ),
            );
          },
        );

    final userId = _userId;
    if (setup == null || userId == null) return;

    final sourceJson = widget.liveSource.toJson();
    sourceJson.addAll(_simulatedDeviceJsons(setup));
    final updatedSource = PersonalLiveSource.fromJson(sourceJson);
    try {
      await savePersonalLiveSource(userId, updatedSource);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the device setup.')),
      );
      return;
    }

    if (!mounted) return;
    widget.onLiveSourceChanged(updatedSource);
  }

  Map<String, dynamic> _simulatedDeviceJsons(
    ({_SetupMeasure measure, _SimulationChoice pattern}) setup,
  ) {
    final measureTypes = switch (setup.measure) {
      _SetupMeasure.bloodPressure => [MeasureType.bpSys, MeasureType.bpDia],
      _SetupMeasure.heartRate => [MeasureType.heartRate],
      _SetupMeasure.respRate => [MeasureType.respRate],
      _SetupMeasure.temperature => [MeasureType.temperature],
      _SetupMeasure.bloodOx => [MeasureType.bloodOx],
    };

    return {
      for (final measureType in measureTypes)
        measureType.name: _simulatedDeviceJson(
          measureType,
          setup.pattern.pattern,
          setup.pattern.whichInterval,
        ),
    };
  }

  Map<String, dynamic> _simulatedDeviceJson(
    MeasureType measureType,
    SimulationPattern pattern,
    int whichInterval,
  ) {
    final isDoubleMeasure =
        measureType == MeasureType.temperature ||
        measureType == MeasureType.bloodOx;
    if (isDoubleMeasure) {
      return SimulatedDevice<double>(
        initialPattern: pattern,
        measureType: measureType,
        whichInterval: whichInterval,
      ).toJson();
    }
    return SimulatedDevice<int>(
      initialPattern: pattern,
      measureType: measureType,
      whichInterval: whichInterval,
    ).toJson();
  }

  String _measureLabel(_SetupMeasure measure) => switch (measure) {
    _SetupMeasure.bloodPressure => 'Blood pressure',
    _SetupMeasure.heartRate => 'Heart rate',
    _SetupMeasure.respRate => 'Respiratory rate',
    _SetupMeasure.temperature => 'Temperature',
    _SetupMeasure.bloodOx => 'Blood oxygen',
  };

  Future<void> _startRecord() async {
    final snapshot = Map<MeasureType, num>.from(_latestValues);
    final capturedAt = DateTime.now().toUtc();
    final deviceMeasures = _measureDetails
        .where((detail) => widget.liveSource.hasDevice(detail.measure))
        .toList();
    final manualMeasures = _measureDetails
        .where((detail) => !widget.liveSource.hasDevice(detail.measure))
        .toList();
    final controllers = {
      for (final detail in manualMeasures)
        detail.measure: TextEditingController(),
    };
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    String? saveError;

    int? valueFor(MeasureType measure) {
      if (widget.liveSource.hasDevice(measure)) {
        return snapshot[measure]?.round();
      }
      final text = controllers[measure]?.text.trim() ?? '';
      return text.isEmpty ? null : int.parse(text);
    }

    try {
      final didSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Record Measures'),
            content: SizedBox(
              width: 460,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Measures',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (deviceMeasures.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No device measures configured.'),
                          ),
                        for (final detail in deviceMeasures)
                          _buildDeviceMeasureRow(
                            detail.label,
                            detail.unit,
                            snapshot[detail.measure],
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Manual',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (manualMeasures.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('All measures have devices.'),
                          ),
                        for (final detail in manualMeasures)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextFormField(
                              controller: controllers[detail.measure],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              decoration: InputDecoration(
                                labelText: detail.label,
                                suffixText: detail.unit,
                              ),
                              validator: (text) {
                                final value = text?.trim() ?? '';
                                if (value.isEmpty ||
                                    int.tryParse(value) != null) {
                                  return null;
                                }
                                return 'Enter a whole number';
                              },
                            ),
                          ),
                        if (saveError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            saveError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final userId = _userId;
                        if (userId == null) {
                          setDialogState(
                            () => saveError = 'Could not identify the user.',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          saveError = null;
                        });
                        try {
                          await ApiService.recordMeasures(
                            userId: userId,
                            data: MeasureModelData(
                              timestamp: capturedAt,
                              bpSysPressure: valueFor(MeasureType.bpSys),
                              bpDiaPressure: valueFor(MeasureType.bpDia),
                              heartRate: valueFor(MeasureType.heartRate),
                              respiratoryRate: valueFor(MeasureType.respRate),
                              temperature: valueFor(MeasureType.temperature),
                              bloodOx: valueFor(MeasureType.bloodOx),
                            ),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSaving = false;
                            saveError = 'Could not save measures: $error';
                          });
                        }
                      },
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save snapshot'),
              ),
            ],
          ),
        ),
      );

      if (didSave == true && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Measures saved.')));
      }
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  Widget _buildDeviceMeasureRow(String label, String unit, num? value) {
    final reading = value == null
        ? 'Waiting for reading'
        : '${value is double ? value.toStringAsFixed(1) : value} $unit';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(reading, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
