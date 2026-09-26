import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/views/components/live_view.dart';

class PersonalHomePage extends StatefulWidget {
  const PersonalHomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PersonalHomePageState();
  }
}

class _PersonalHomePageState extends State<PersonalHomePage> {
  @override
  Widget build(BuildContext bc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const LiveView(title: 'Live View:', placeholder: 'No Devices'),
        Container(height: 16.0),
        Row(
          children: [
            ElevatedButton(
              onPressed: startRecord,
              child: Row(
                children: [Icon(Icons.save), Text(" Record Measures")],
              ),
            ),
          ],
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     Expanded(child: _buildSummariesTile()),
        //     Expanded(child: _buildShareTile()),
        //   ],
        // ),
      ],
    );
  }

  void startRecord() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        actions: [],
        content: ListView(children: []),
      ),
    );
  }
}
