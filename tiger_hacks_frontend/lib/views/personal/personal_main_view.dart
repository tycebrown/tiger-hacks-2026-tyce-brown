import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/util.dart' show isMobile, themeSeedColor;
import 'package:tiger_hacks_frontend/views/components/log_out_button.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_caretakers_page.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_home_page.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_summaries_page.dart';

enum PersonalPage {
  HomePage,
  SummariesPage,
  MyCaretakers,
  // History,
}

int personalPageToIndex(PersonalPage page) {
  switch (page) {
    case .HomePage:
      return 0;
    case .SummariesPage:
      return 1;
    case .MyCaretakers:
      return 2;
    // case .History:
    //   return 3;
  }
}

PersonalPage indexToPersonalPage(int index) {
  switch (index) {
    case 0:
      return .HomePage;
    case 1:
      return .SummariesPage;
    case 2:
      return .MyCaretakers;
    // case 3:
    //   return .History;
  }
  throw Exception("Wtf????");
}

const navigationDestinations = [
  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
  NavigationDestination(icon: Icon(Icons.show_chart), label: "Summaries"),
  NavigationDestination(icon: Icon(Icons.favorite), label: "My Caretakers"),
  // NavigationDestination(icon: Icon(Icons.history), label: "History"),
];

const navigationRailDestinations = [
  NavigationRailDestination(icon: Icon(Icons.home), label: Text("Home")),
  NavigationRailDestination(
    icon: Icon(Icons.show_chart),
    label: Text("Summaries"),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.favorite),
    label: Text("My Caretakers"),
  ),
  // NavigationRailDestination(icon: Icon(Icons.history), label: Text("History")),
];

class PersonalMainView extends StatefulWidget {
  PersonalMainView({super.key});

  @override
  State<PersonalMainView> createState() => _PersonalMainViewState();
}

class _PersonalMainViewState extends State<PersonalMainView> {
  PersonalPage currentPage = .HomePage;
  PersonalLiveSource _liveSource = PersonalLiveSource.fromDevices();
  final List<StreamSubscription<dynamic>> _liveSubscriptions = [];
  final Set<MeasureType> _criticalMeasures = {};
  bool _sourceLoaded = false;
  bool _emergencyAlertShowing = false;
  int _sourceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadLiveSource();
  }

  Future<void> _loadLiveSource() async {
    final userId = context.read<GlobalState>().user?.id;
    var liveSource = PersonalLiveSource.fromDevices();
    if (userId != null) {
      try {
        liveSource = await loadDefaultPersonalLiveSource(userId);
      } catch (_) {
        // Use the empty source if persisted settings are unavailable.
      }
    }
    if (!mounted) {
      await liveSource.dispose();
      return;
    }
    final previousSource = _liveSource;
    setState(() {
      _liveSource = liveSource;
      _sourceLoaded = true;
    });
    _watchLiveSource(liveSource);
    await previousSource.dispose();
  }

  void _updateLiveSource(PersonalLiveSource liveSource) {
    if (identical(_liveSource, liveSource)) return;
    final previousSource = _liveSource;
    setState(() => _liveSource = liveSource);
    _watchLiveSource(liveSource);
    previousSource.dispose();
  }

  void _watchLiveSource(PersonalLiveSource liveSource) {
    final generation = ++_sourceGeneration;
    for (final subscription in _liveSubscriptions) {
      unawaited(subscription.cancel());
    }
    _liveSubscriptions.clear();
    _criticalMeasures.clear();

    void watch<T extends num>(MeasureType measure, Stream<T>? stream) {
      if (stream == null) return;
      _liveSubscriptions.add(
        stream.listen((value) {
          if (!mounted || generation != _sourceGeneration) return;
          if (rangeForValue(measure, value) == Range.Critical) {
            if (_criticalMeasures.add(measure)) {
              unawaited(_showEmergencyAlert(measure, value));
            }
          } else {
            _criticalMeasures.remove(measure);
          }
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

  Future<void> _showEmergencyAlert(MeasureType measure, num value) async {
    if (!mounted || _emergencyAlertShowing) return;
    _emergencyAlertShowing = true;
    final isSimulated = _liveSource.isSimulated(measure);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: isSimulated,
        builder: (dialogContext) => PopScope(
          canPop: isSimulated,
          child: AlertDialog(
            title: const Text('Emergency alert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 72,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Call 911 immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_measureLabel(measure)} is critically '
                  '${criticalDirectionForValue(measure, value).name}.',
                  textAlign: TextAlign.center,
                ),
                if (isSimulated) ...[
                  const SizedBox(height: 12),
                  Text(
                    'SIMULATED VALUE (since this is a simulated value, this dialog may be dismissed)',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (isSimulated)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Dismiss'),
                ),
            ],
          ),
        ),
      );
    } finally {
      _emergencyAlertShowing = false;
    }
  }

  String _measureLabel(MeasureType measure) => switch (measure) {
    MeasureType.bpSys => 'Blood pressure systolic',
    MeasureType.bpDia => 'Blood pressure diastolic',
    MeasureType.heartRate => 'Heart rate',
    MeasureType.respRate => 'Respiratory rate',
    MeasureType.temperature => 'Temperature',
    MeasureType.bloodOx => 'Blood oxygen',
  };

  @override
  void dispose() {
    _sourceGeneration++;
    for (final subscription in _liveSubscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_liveSource.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeSeedColor,
        title: const Text(
          'LiveWire',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: Icon(Icons.monitor_heart, size: 32.0, color: Colors.white),
        actions: [LogOutButton()],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              destinations: navigationDestinations,
              onDestinationSelected: (value) =>
                  setState(() => currentPage = indexToPersonalPage(value)),
            )
          : null,

      body: SafeArea(
        child: Row(
          children: [
            ?(!isMobile
                ? NavigationRail(
                    extended: true,
                    destinations: navigationRailDestinations,
                    onDestinationSelected: (value) => setState(
                      () => currentPage = indexToPersonalPage(value),
                    ),
                    selectedIndex: personalPageToIndex(currentPage),
                  )
                : null),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildContent() {
    switch (currentPage) {
      case .HomePage:
        if (!_sourceLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return PersonalHomePage(
          liveSource: _liveSource,
          onLiveSourceChanged: _updateLiveSource,
        );
      case .SummariesPage:
        return PersonalSummariesPage();
      case .MyCaretakers:
        return PersonalCaretakersPage();
      // case .History:
      //   return PersonalHistoryPage();
    }
  }

  Widget? _buildFloatingActionButton() {
    return null;
  }
}
