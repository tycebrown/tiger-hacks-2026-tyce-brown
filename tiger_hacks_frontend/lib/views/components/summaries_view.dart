import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';

class SummariesView extends StatefulWidget {
  final Future<List<MeasureModel>> Function(DateTime, DateTime) loadData;
  final bool compact;

  const new({super.key, required this.loadData, this.compact = false});

  @override
  State<SummariesView> createState() => _SummariesViewState();
}

class _SummariesViewState extends State<SummariesView> {
  Duration displayRange = const Duration(days: 7);

  _SummariesViewState();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(displayRange);
    final end = now;

    return ListView(
      children: [
        Text(
          "Summaries:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: widget.compact ? 14 : 16,
          ),
        ),
        DropdownButton<Duration>(
          isDense: widget.compact,
          value: displayRange,
          items: [
            DropdownMenuItem(
              value: const Duration(days: 7),
              child: Text("Past Week"),
            ),
            DropdownMenuItem(
              value: const Duration(days: 31),
              child: Text("Past Month"),
            ),
          ],
          onChanged: (newDisplayRange) {
            if (newDisplayRange != null) {
              setState(() => displayRange = newDisplayRange);
            }
          },
        ),
        FutureBuilder(
          future: widget.loadData(start, end),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == .waiting ||
                snapshot.connectionState == .active) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              return _buildSummariesFromData(snapshot.data!, start, end);
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ],
    );
  }

  Widget _buildSummariesFromData(
    List<MeasureModel> data,
    DateTime state,
    DateTime end,
  ) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No measurements for this period.')),
      );
    }

    final sortedData = [...data]
      ..sort((first, second) => first.timestamp.compareTo(second.timestamp));

    return Column(
      children: [
        _buildPairedChart(
          title: 'Blood pressure',
          start: state,
          end: end,
          records: sortedData,
          firstName: 'Systolic',
          firstUnit: 'mmHg',
          firstValue: (record) => record.bpSysPressure,
          firstColor: const Color(0xFFbd4b3c),
          secondName: 'Diastolic',
          secondUnit: 'mmHg',
          secondValue: (record) => record.bpDiaPressure,
          secondColor: const Color(0xFF326f9b),
        ),
        SizedBox(height: widget.compact ? 8 : 12),
        _buildPairedChart(
          title: 'Heart and respiratory rate',
          start: state,
          end: end,
          records: sortedData,
          firstName: 'Heart rate',
          firstUnit: 'bpm',
          firstValue: (record) => record.heartRate,
          firstColor: const Color(0xFFbd4b3c),
          secondName: 'Respiratory rate',
          secondUnit: 'breaths/min',
          secondValue: (record) => record.respiratoryRate,
          secondColor: const Color(0xFF326f9b),
          normalize: true,
        ),
        SizedBox(height: widget.compact ? 8 : 12),
        _buildPairedChart(
          title: 'Temperature and blood oxygen',
          start: state,
          end: end,
          records: sortedData,
          firstName: 'Temperature',
          firstUnit: '°C',
          firstValue: (record) => record.temperature,
          firstColor: const Color(0xFFbd4b3c),
          secondName: 'Blood oxygen',
          secondUnit: '%',
          secondValue: (record) => record.bloodOx,
          secondColor: const Color(0xFF326f9b),
          normalize: true,
        ),
      ],
    );
  }

  Widget _buildPairedChart({
    required String title,
    required DateTime start,
    required DateTime end,
    required List<MeasureModel> records,
    required String firstName,
    required String firstUnit,
    required int? Function(MeasureModel) firstValue,
    required Color firstColor,
    required String secondName,
    required String secondUnit,
    required int? Function(MeasureModel) secondValue,
    required Color secondColor,
    bool normalize = false,
  }) {
    final series = [
      _buildSeries(
        name: firstName,
        unit: firstUnit,
        color: firstColor,
        records: records,
        start: start,
        valueOf: firstValue,
        normalize: normalize,
      ),
      _buildSeries(
        name: secondName,
        unit: secondUnit,
        color: secondColor,
        records: records,
        start: start,
        valueOf: secondValue,
        normalize: normalize,
      ),
    ];
    final populatedSeries = series
        .where((item) => item.points.isNotEmpty)
        .toList();
    final allValues = populatedSeries
        .expand((item) => item.points)
        .map((point) => point.value)
        .toList();

    var minY = 0.0;
    var maxY = 100.0;
    if (!normalize && allValues.isNotEmpty) {
      final lowest = allValues.reduce((a, b) => a < b ? a : b);
      final highest = allValues.reduce((a, b) => a > b ? a : b);
      final padding = highest == lowest ? 5.0 : (highest - lowest) * 0.12;
      minY = lowest - padding;
      maxY = highest + padding;
    }

    final maxX =
        end.difference(start).inMicroseconds / Duration.microsecondsPerDay;
    final chartMaxX = maxX > 0 ? maxX : 1.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 8 : 12,
        widget.compact ? 8 : 12,
        widget.compact ? 8 : 12,
        widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [for (final item in series) _buildLegendItem(item)],
          ),
          if (normalize && !widget.compact)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Each line is scaled to its own range. Touch points for readings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          if (allValues.isEmpty)
            SizedBox(
              height: widget.compact ? 96 : 140,
              child: Center(child: Text('No readings for these measures.')),
            )
          else
            SizedBox(
              height: widget.compact ? 142 : 190,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: chartMaxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: !normalize,
                        reservedSize: widget.compact ? 30 : 38,
                        getTitlesWidget: (value, meta) => Text(
                          value.round().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: widget.compact ? 22 : 28,
                        interval: chartMaxX / 3,
                        getTitlesWidget: (value, meta) {
                          final date = start.add(
                            Duration(
                              microseconds:
                                  (value * Duration.microsecondsPerDay).round(),
                            ),
                          );
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${date.month}/${date.day}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final item = populatedSeries[spot.barIndex];
                        final point = item.points[spot.spotIndex];
                        final date = point.timestamp.toLocal();
                        final time =
                            '${date.month}/${date.day} '
                            '${date.hour.toString().padLeft(2, '0')}:'
                            '${date.minute.toString().padLeft(2, '0')}';
                        return LineTooltipItem(
                          '${item.name}: ${point.value.toStringAsFixed(0)} '
                          '${item.unit}\n$time',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    for (final item in populatedSeries)
                      LineChartBarData(
                        spots: [for (final point in item.points) point.spot],
                        color: item.color,
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(_MeasureSeries series) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: series.color),
        const SizedBox(width: 6),
        Text(
          '${series.name} (${series.unit})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  _MeasureSeries _buildSeries({
    required String name,
    required String unit,
    required Color color,
    required List<MeasureModel> records,
    required DateTime start,
    required int? Function(MeasureModel) valueOf,
    required bool normalize,
  }) {
    final rawPoints = <_MeasurePoint>[];
    for (final record in records) {
      final value = valueOf(record);
      if (value == null) continue;
      final x =
          record.timestamp.difference(start).inMicroseconds /
          Duration.microsecondsPerDay;
      rawPoints.add(
        _MeasurePoint(
          spot: FlSpot(x, value.toDouble()),
          value: value.toDouble(),
          timestamp: record.timestamp,
        ),
      );
    }

    if (!normalize || rawPoints.isEmpty) {
      return _MeasureSeries(name, unit, color, rawPoints);
    }

    final values = rawPoints.map((point) => point.value).toList();
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final points = rawPoints.map((point) {
      final y = highest == lowest
          ? 50.0
          : (point.value - lowest) / (highest - lowest) * 100;
      return _MeasurePoint(
        spot: FlSpot(point.spot.x, y),
        value: point.value,
        timestamp: point.timestamp,
      );
    }).toList();
    return _MeasureSeries(name, unit, color, points);
  }
}

class _MeasureSeries {
  const _MeasureSeries(this.name, this.unit, this.color, this.points);

  final String name;
  final String unit;
  final Color color;
  final List<_MeasurePoint> points;
}

class _MeasurePoint {
  const _MeasurePoint({
    required this.spot,
    required this.value,
    required this.timestamp,
  });

  final FlSpot spot;
  final double value;
  final DateTime timestamp;
}
