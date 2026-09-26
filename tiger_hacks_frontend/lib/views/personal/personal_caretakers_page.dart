import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';

class PersonalCaretakersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<GlobalState>().user;
    if (user == null) {
      return const Center(child: Text('Log in to view caretakers.'));
    }
    final userId = user.id;
    return FutureBuilder(
      future: ApiService.getCaretakers(userId),
      builder: (ctx, snap) {
        if (snap.connectionState == .waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Could not load caretakers.'));
        }
        if (snap.hasData && snap.data!.isEmpty) {
          return Center(
            child: Text('No caretakers are linked to your account.'),
          );
        }
        if (snap.hasData) return _buildCaretakersView(snap.data!);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCaretakersView(List<SharedUserModel> caretakers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: caretakers.length,
      itemBuilder: (context, index) {
        final caretaker = caretakers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Icon(Icons.medical_services_outlined, size: 28),
              ),
              title: Text(
                caretaker.username,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${caretaker.role.name[0].toUpperCase()}${caretaker.role.name.substring(1)}'
                  '  ·  Connection #${caretaker.sharepointId}',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
