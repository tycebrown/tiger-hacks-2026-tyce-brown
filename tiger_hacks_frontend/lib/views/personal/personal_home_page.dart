import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/util.dart';

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
        _buildLiveView(),
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

  _buildLiveView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Live View:"),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: themeSeedColor.withAlpha(50),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Center(
            child: Text(
              "No Devices",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
    );
  }

  startRecord() {
    showDialog(context: context, builder: builder)
  }

  // _buildSummariesTile() {
  //   return Container(
  //     height: 200,
  //     child: Card(
  //       child: Padding(
  //         padding: EdgeInsets.all(8),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Icon(Icons.show_chart),
  //             Text(
  //               ' Summaries',
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // _buildShareTile() {
  //   return Container(
  //     height: 200,
  //     child: Card(
  //       child: Padding(
  //         padding: EdgeInsets.all(8),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Icon(Icons.favorite),
  //             Text(
  //               ' Caretakers/Shared Data',
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
