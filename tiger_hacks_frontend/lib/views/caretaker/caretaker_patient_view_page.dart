import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/views/components/live_view.dart';
import 'package:tiger_hacks_frontend/views/components/summaries_view.dart';

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
          liveSource: PersonalLiveSource.fromDevices(),
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
