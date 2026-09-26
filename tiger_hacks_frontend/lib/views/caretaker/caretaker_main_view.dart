import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
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

  @override
  void initState() {
    super.initState();
    _patientsFuture = ApiService.getPatients(widget.caretakerId);
  }

  @override
  void didUpdateWidget(covariant _CaretakerDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caretakerId != widget.caretakerId) {
      _patientsFuture = ApiService.getPatients(widget.caretakerId);
      _selectedPatient = null;
      _selectedIndex = 0;
    }
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
    return CaretakerPatientViewPage(
      key: ValueKey(patient.individualId),
      caretakerId: widget.caretakerId,
      patients: patients,
      selectedPatient: patient,
      onPatientSelected: (nextPatient) {
        setState(() => _selectedPatient = nextPatient);
      },
    );
  }
}
