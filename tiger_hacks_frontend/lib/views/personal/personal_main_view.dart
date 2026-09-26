import 'package:flutter/material.dart';
import 'package:tiger_hacks_frontend/util.dart' show isMobile;

enum PersonalPage { HomePage, SummariesPage, MyCaretakers, History }

int personalPageToIndex(PersonalPage page) {
  switch (page) {
    case .HomePage:
      return 0;
    case .SummariesPage:
      return 1;
    case .MyCaretakers:
      return 2;
    case .History:
      return 3;
  }
}

PersonalPage indexToPersonalPage(int index) {
  switch (index) {
    case 0:
      return .HomePage;
    case 1:
      return .SummariesPage;
    case 2:
      return .MyCaretakers;
    case 3:
      return .History;
  }
  throw Exception("Wtf????");
}

const navigationDestinations = [
  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
  NavigationDestination(icon: Icon(Icons.show_chart), label: "Summaries"),
  NavigationDestination(icon: Icon(Icons.share), label: "My Caretakers"),
  NavigationDestination(icon: Icon(Icons.history), label: "History"),
];

const navigationRailDestinations = [
  NavigationRailDestination(icon: Icon(Icons.home), label: Text("Home")),
  NavigationRailDestination(
    icon: Icon(Icons.show_chart),
    label: Text("Summaries"),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.share),
    label: Text("My Caretakers"),
  ),
  NavigationRailDestination(icon: Icon(Icons.history), label: Text("History")),
];

class PersonalMainView extends StatefulWidget {
  PersonalMainView({super.key});

  @override
  State<PersonalMainView> createState() => _PersonalMainViewState();
}

class _PersonalMainViewState extends State<PersonalMainView> {
  PersonalPage currentPage = .HomePage;

  @override
  Widget build(BuildContext bc) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LiveWire',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.monitor_heart),
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              destinations: navigationDestinations,
              onDestinationSelected: (value) => 0,
            )
          : null,

      body: Row(
        children: [
          ?(!isMobile
              ? NavigationRail(
                  destinations: navigationRailDestinations,
                  selectedIndex: 0,
                )
              : null),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildContent() {
    switch (currentPage) {
      case .HomePage:
        return PersonalHomePage();
      case .SummariesPage:
        return PersonalSummariesPage();
      case .MyCaretakers:
        return PersonalCaretakersPage();
      case .History:
        return PersonalHistoryPage();
    }
    return null;
  }

  Widget? _buildFloatingActionButton() {
    switch (currentPage) {
      case .HomePage:
        return PersonalHomePage();
      case .SummariesPage:
        return null;
      case .MyCaretakers:
        return null;
      case .History:
        return null;
    }
    return null;
  }
}

class PersonalHistoryPage extends StatefulWidget {
  @override
  State<PersonalHistoryPage> createState() => _PersonalHistoryPageState();
}

class _PersonalHistoryPageState extends State<PersonalHistoryPage> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class PersonalCaretakersPage extends StatefulWidget {
  @override
  State<PersonalCaretakersPage> createState() => _PersonalCaretakersPageState();
}

class _PersonalCaretakersPageState extends State<PersonalCaretakersPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class PersonalSummariesPage extends StatefulWidget {
  @override
  State<PersonalSummariesPage> createState() => _PersonalSummariesPageState();
}

class _PersonalSummariesPageState extends State<PersonalSummariesPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

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
      children: [
        _buildLiveView(),
        Row(children: [_buildSummariesTile(), _buildShareTile()]),
      ],
    );
  }

  _buildLiveView() {
    return Container(
      height: 200,
      width: 400,
      color: Colors.grey,
      child: Center(
        child: Text(
          "Live View",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  _buildSummariesTile() {
    return Expanded(child: Card(child: Text('Toodles')));
  }

  _buildShareTile() {
    return Expanded(child: Card(child: Text('Toodles')));
  }
}
