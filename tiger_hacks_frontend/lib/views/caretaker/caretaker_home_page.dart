import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';

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
