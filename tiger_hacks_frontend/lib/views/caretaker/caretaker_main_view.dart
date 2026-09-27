import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/live_wire/device_streamed_live_source.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_wire_mqtt_client.dart';
import 'package:tiger_hacks_frontend/model/user.dart';
import 'package:tiger_hacks_frontend/util.dart' show isMobile, themeSeedColor;
import 'package:tiger_hacks_frontend/views/components/log_out_button.dart';
import 'package:tiger_hacks_frontend/views/caretaker/caretaker_home_page.dart';
import 'package:tiger_hacks_frontend/views/caretaker/caretaker_patient_view_page.dart';

const _caretakerNavigationDestinations = [
  NavigationDestination(icon: Icon(Icons.people_outline), label: 'Patients'),
  NavigationDestination(
    icon: Icon(Icons.monitor_heart_outlined),
    label: 'Overview',
  ),
];

const _caretakerRailDestinations = [
  NavigationRailDestination(
    icon: Icon(Icons.people_outline),
    label: Text('Patients'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.monitor_heart_outlined),
    label: Text('Overview'),
  ),
];

class CaretakerMainView extends StatelessWidget {
  const CaretakerMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<GlobalState>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Log in to view your patients.')),
      );
    }
    if (user.role != UserRole.caretaker) {
      return const Scaffold(
        body: Center(child: Text('This page is for caretakers.')),
      );
    }

    return _CaretakerDashboard(caretakerId: user.id);
  }
}

class _CaretakerDashboard extends StatefulWidget {
  const _CaretakerDashboard({required this.caretakerId});

  final int caretakerId;

  @override
  State<_CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<_CaretakerDashboard> {
  late Future<List<SharedUserModel>> _patientsFuture;
  SharedUserModel? _selectedPatient;
  int _selectedIndex = 0;
  late final LiveWireMqttClient _mqttClient;
  final Map<int, DeviceStreamedLiveSource> _liveSources = {};
  final Map<int, StreamSubscription<void>> _emergencySubscriptions = {};
  final Map<int, SharedUserModel> _patientsById = {};
  final Queue<SharedUserModel> _pendingEmergencyAlerts = Queue();
  bool _showingEmergencyAlert = false;

  @override
  void initState() {
    super.initState();
    _mqttClient = LiveWireMqttClient();
    unawaited(_mqttClient.connect());
    _patientsFuture = _loadPatients();
  }

  @override
  void didUpdateWidget(covariant _CaretakerDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caretakerId != widget.caretakerId) {
      _patientsFuture = _loadPatients();
      _selectedPatient = null;
      _selectedIndex = 0;
    }
  }

  Future<List<SharedUserModel>> _loadPatients() async {
    final patients = await ApiService.getPatients(widget.caretakerId);
    if (mounted) _syncPatientSources(patients);
    return patients;
  }

  void _syncPatientSources(List<SharedUserModel> patients) {
    final nextPatientsById = {
      for (final patient in patients) patient.individualId: patient,
    };
    for (final userId in _liveSources.keys.toList()) {
      if (nextPatientsById.containsKey(userId)) continue;
      unawaited(_emergencySubscriptions.remove(userId)?.cancel());
      unawaited(_liveSources.remove(userId)?.dispose());
    }
    _patientsById
      ..clear()
      ..addAll(nextPatientsById);

    for (final patient in patients) {
      if (_liveSources.containsKey(patient.individualId)) continue;
      final source = DeviceStreamedLiveSource(userId: patient.individualId);
      _liveSources[patient.individualId] = source;
      _emergencySubscriptions[patient.individualId] = source.emergencies.listen(
        (_) => _queueEmergencyAlert(patient.individualId),
      );
      source.attach(_mqttClient);
    }
  }

  void _queueEmergencyAlert(int patientId) {
    final patient = _patientsById[patientId];
    if (!mounted || patient == null) return;
    _pendingEmergencyAlerts.add(patient);
    unawaited(_showNextEmergencyAlert());
  }

  Future<void> _showNextEmergencyAlert() async {
    if (!mounted || _showingEmergencyAlert || _pendingEmergencyAlerts.isEmpty) {
      return;
    }
    _showingEmergencyAlert = true;
    final patient = _pendingEmergencyAlerts.removeFirst();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
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
                '${patient.username} is having an emergency.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    } finally {
      _showingEmergencyAlert = false;
    }
    if (mounted && _pendingEmergencyAlerts.isNotEmpty) {
      unawaited(_showNextEmergencyAlert());
    }
  }

  @override
  void dispose() {
    for (final subscription in _emergencySubscriptions.values) {
      unawaited(subscription.cancel());
    }
    for (final source in _liveSources.values) {
      unawaited(source.dispose());
    }
    unawaited(_mqttClient.dispose());
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
        leading: const Icon(Icons.monitor_heart, size: 32, color: Colors.white),
        actions: [LogOutButton()],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              destinations: _caretakerNavigationDestinations,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              NavigationRail(
                extended: true,
                destinations: _caretakerRailDestinations,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: FutureBuilder<List<SharedUserModel>>(
                  future: _patientsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == .waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load patients.'),
                      );
                    }
                    final patients = snapshot.data ?? const <SharedUserModel>[];
                    if (patients.isEmpty) {
                      return const Center(
                        child: Text('No patients are linked yet.'),
                      );
                    }
                    return _buildContent(patients);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildContent(List<SharedUserModel> patients) {
    if (_selectedIndex == 0) {
      return CaretakerHomePage(
        patients: patients,
        onPatientSelected: (patient) {
          setState(() {
            _selectedPatient = patient;
            _selectedIndex = 1;
          });
        },
      );
    }

    var patient = _selectedPatient;
    if (patient == null && patients.isNotEmpty) {
      patient = patients[0];
    }
    patient!;
    final liveSource = _liveSources[patient.individualId];
    if (liveSource == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CaretakerPatientViewPage(
      key: ValueKey(patient.individualId),
      caretakerId: widget.caretakerId,
      patients: patients,
      selectedPatient: patient,
      liveSource: liveSource,
      onPatientSelected: (nextPatient) {
        setState(() => _selectedPatient = nextPatient);
      },
    );
  }
}
