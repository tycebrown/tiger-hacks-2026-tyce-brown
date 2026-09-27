import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/util.dart' show themeSeedColor;

class LiveView extends StatefulWidget {
  final LiveSource liveSource;
  final Map<MeasureType, num> initialValues;
  final String title;
  final bool compact;

  const LiveView({
    super.key,
    required this.title,
    required this.liveSource,
    required this.initialValues,
    this.compact = false,
  });

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return compact
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title),
                const SizedBox(height: 6),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _buildView(),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: _buildView(),
              ),
            ],
          );
  }

  Widget _buildView() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _buildMeasure(
              'Blood Pressure',
              _buildBloodPressure(),
              isSimulated:
                  widget.liveSource.isSimulated(MeasureType.bpSys) &&
                  widget.liveSource.isSimulated(MeasureType.bpDia),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMeasure(
                    'Heart Rate',
                    _buildMetric<int>(
                      stream: widget.liveSource.heartRateStream,
                      measureType: MeasureType.heartRate,
                      unit: 'bpm',
                    ),
                    isSimulated: widget.liveSource.isSimulated(
                      MeasureType.heartRate,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildMeasure(
                    'Respiratory Rate',
                    _buildMetric<int>(
                      stream: widget.liveSource.respRateStream,
                      measureType: MeasureType.respRate,
                      unit: 'breaths/min',
                    ),
                    isSimulated: widget.liveSource.isSimulated(
                      MeasureType.respRate,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildMeasure(
                    'Blood Oxygen',
                    _buildMetric<double>(
                      stream: widget.liveSource.bloodOxStream,
                      measureType: MeasureType.bloodOx,
                      unit: '%',
                    ),
                    isSimulated: widget.liveSource.isSimulated(
                      MeasureType.bloodOx,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildMeasure(
                    'Temperature',
                    _buildMetric<double>(
                      stream: widget.liveSource.tempStream,
                      measureType: MeasureType.temperature,
                      unit: '°F',
                    ),
                    isSimulated: widget.liveSource.isSimulated(
                      MeasureType.temperature,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasure(
    String title,
    Widget reading, {
    required bool isSimulated,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeSeedColor.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isSimulated)
                Tooltip(
                  message: 'Simulated device',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'SIM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(child: reading),
        ],
      ),
    );
  }

  Widget _buildBloodPressure() {
    return StreamBuilder<int>(
      stream: widget.liveSource.bpSysStream,
      initialData: widget.initialValues[MeasureType.bpSys]?.toInt(),
      builder: (context, systolicSnapshot) {
        return StreamBuilder<int>(
          stream: widget.liveSource.bpDiaStream,
          initialData: widget.initialValues[MeasureType.bpDia]?.toInt(),
          builder: (context, diastolicSnapshot) {
            final systolic = systolicSnapshot.data;
            final diastolic = diastolicSnapshot.data;
            if (systolic == null || diastolic == null) {
              return _buildEmptyReading('--/--');
            }

            final systolicRange = rangeForValue(MeasureType.bpSys, systolic);
            final diastolicRange = rangeForValue(MeasureType.bpDia, diastolic);
            final range = _worstRange(systolicRange, diastolicRange);
            return _readingContent('$systolic / $diastolic', 'mmHg', range);
          },
        );
      },
    );
  }

  Widget _buildMetric<T extends num>({
    required Stream<T>? stream,
    required MeasureType measureType,
    required String unit,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: widget.initialValues[measureType] is double
          ? widget.initialValues[measureType] as T?
          : widget.initialValues[measureType]?.toInt() as T?,
      builder: (context, snapshot) {
        final value = snapshot.data;
        if (value == null) return _buildEmptyReading('--');

        return _readingContent(
          value is double ? value.toStringAsFixed(1) : value.toString(),
          unit,
          rangeForValue(measureType, value),
        );
      },
    );
  }

  Widget _buildEmptyReading(String text) {
    final compact = widget.compact;
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 28 : 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _readingContent(String value, String unit, Range range) {
    final compact = widget.compact;
    final color = switch (range) {
      Range.Healthy => Colors.green,
      Range.Unhealthy => Colors.orange,
      Range.Critical => Colors.red,
    };
    final valueSize = compact ? 28.0 : 48.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(unit, style: TextStyle(fontSize: compact ? 11 : null)),
          Text(
            range.name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : null,
            ),
          ),
        ],
      ),
    );
  }

  Range _worstRange(Range first, Range second) {
    return first.index >= second.index ? first : second;
  }
}
