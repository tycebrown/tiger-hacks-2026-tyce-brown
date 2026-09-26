import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/user.dart';
import 'package:tiger_hacks_frontend/util.dart' show isMobile, themeSeedColor;
import 'package:tiger_hacks_frontend/views/components/live_view.dart';
import 'package:tiger_hacks_frontend/views/components/log_out_button.dart';
import 'package:tiger_hacks_frontend/views/components/summaries_view.dart';

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

class CaretakerHomePage extends StatelessWidget {
  const CaretakerHomePage({
    super.key,
    required this.patients,
    required this.onPatientSelected,
  });

  final List<SharedUserModel> patients;
  final ValueChanged<SharedUserModel> onPatientSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            leading: const CircleAvatar(
              radius: 26,
              child: Icon(Icons.person_outline, size: 28),
            ),
            title: Text(
              patient.username,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text('Patient ID ${patient.individualId}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onPatientSelected(patient),
          ),
        );
      },
    );
  }
}

class CaretakerPatientViewPage extends StatelessWidget {
  const CaretakerPatientViewPage({
    super.key,
    required this.caretakerId,
    required this.patients,
    required this.selectedPatient,
    required this.onPatientSelected,
  });

  final int caretakerId;
  final List<SharedUserModel> patients;
  final SharedUserModel selectedPatient;
  final ValueChanged<SharedUserModel> onPatientSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final patient in patients)
                ChoiceChip(
                  label: Text(patient.username),
                  selected:
                      patient.individualId == selectedPatient.individualId,
                  onSelected: (selected) {
                    if (selected) onPatientSelected(patient);
                  },
                ),
            ],
          ),
        ),
        LiveView(
          title: 'Live View · ${selectedPatient.username}',
          placeholder: 'Live device view',
          compact: true,
        ),
        Expanded(
          child: SummariesView(
            key: ValueKey(selectedPatient.individualId),
            compact: true,
            loadData: (start, end) => ApiService.queryPersonalMeasures(
              caretakerId: caretakerId,
              individualId: selectedPatient.individualId,
              start: start,
              end: end,
            ),
          ),
        ),
      ],
    );
  }
}
