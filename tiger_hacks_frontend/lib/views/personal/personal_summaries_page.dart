import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/views/components/summaries_view.dart';

class PersonalSummariesPage extends StatelessWidget {
  const PersonalSummariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<GlobalState>().user;
    if (user == null) {
      return const Center(child: Text('Log in to view summaries.'));
    }
    final userId = user.id;

    return SummariesView(
      loadData: (start, end) =>
          ApiService.queryMeasures(userId: userId, start: start, end: end),
    );
  }
}
