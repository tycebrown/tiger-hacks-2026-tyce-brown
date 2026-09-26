import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/user.dart';
import 'package:tiger_hacks_frontend/views/components/summaries_view.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('My patients')),
      body: FutureBuilder<List<SharedUserModel>>(
        future: ApiService.getPatients(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == .waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load patients.'));
          }
          final patients = snapshot.data;
          if (patients == null || patients.isEmpty) {
            return const Center(child: Text('No patients are linked yet.'));
          }
          return CaretakerHomePage(
            caretakerId: user.id,
            patients: patients,
          );
        },
      ),
    );
  }
}

class CaretakerHomePage extends StatelessWidget {
  const CaretakerHomePage({
    super.key,
    required this.caretakerId,
    required this.patients,
  });

  final int caretakerId;
  final List<SharedUserModel> patients;

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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaretakerPatientViewPage(
                  caretakerId: caretakerId,
                  patients: patients,
                  initialPatient: patient,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CaretakerPatientViewPage extends StatefulWidget {
  const CaretakerPatientViewPage({
    super.key,
    required this.caretakerId,
    required this.patients,
    required this.initialPatient,
  });

  final int caretakerId;
  final List<SharedUserModel> patients;
  final SharedUserModel initialPatient;

  @override
  State<CaretakerPatientViewPage> createState() =>
      _CaretakerPatientViewPageState();
}

class _CaretakerPatientViewPageState extends State<CaretakerPatientViewPage> {
  late SharedUserModel _selectedPatient = widget.initialPatient;

  @override
  Widget build(BuildContext context) {
    final selectedPatient = _selectedPatient;
    return Scaffold(
      appBar: AppBar(title: Text(selectedPatient.username)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final patient in widget.patients)
                    ChoiceChip(
                      label: Text(patient.username),
                      selected:
                          patient.individualId == selectedPatient.individualId,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPatient = patient);
                        }
                      },
                    ),
                ],
              ),
            ),
            _buildLiveView(context, selectedPatient),
            Expanded(
              child: SummariesView(
                key: ValueKey(selectedPatient.individualId),
                compact: true,
                loadData: (start, end) => ApiService.queryPersonalMeasures(
                  caretakerId: widget.caretakerId,
                  individualId: selectedPatient.individualId,
                  start: start,
                  end: end,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveView(BuildContext context, SharedUserModel patient) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live View · ${patient.username}'),
          const SizedBox(height: 6),
          Container(
            height: 112,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('Live device view'),
          ),
        ],
      ),
    );
  }
}
