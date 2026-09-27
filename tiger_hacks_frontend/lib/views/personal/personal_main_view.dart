import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/live_wire/live_source.dart';
import 'package:tiger_hacks_frontend/util.dart' show isMobile, themeSeedColor;
import 'package:tiger_hacks_frontend/views/components/log_out_button.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_caretakers_page.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_home_page.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_summaries_page.dart';

enum PersonalPage {
  HomePage,
  SummariesPage,
  MyCaretakers,
  // History,
}

int personalPageToIndex(PersonalPage page) {
  switch (page) {
    case .HomePage:
      return 0;
    case .SummariesPage:
      return 1;
    case .MyCaretakers:
      return 2;
    // case .History:
    //   return 3;
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
    // case 3:
    //   return .History;
  }
  throw Exception("Wtf????");
}

const navigationDestinations = [
  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
  NavigationDestination(icon: Icon(Icons.show_chart), label: "Summaries"),
  NavigationDestination(icon: Icon(Icons.favorite), label: "My Caretakers"),
  // NavigationDestination(icon: Icon(Icons.history), label: "History"),
];

const navigationRailDestinations = [
  NavigationRailDestination(icon: Icon(Icons.home), label: Text("Home")),
  NavigationRailDestination(
    icon: Icon(Icons.show_chart),
    label: Text("Summaries"),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.favorite),
    label: Text("My Caretakers"),
  ),
  // NavigationRailDestination(icon: Icon(Icons.history), label: Text("History")),
];

class PersonalMainView extends StatefulWidget {
  PersonalMainView({super.key});

  @override
  State<PersonalMainView> createState() => _PersonalMainViewState();
}

class _PersonalMainViewState extends State<PersonalMainView> {
  PersonalPage currentPage = .HomePage;
  PersonalLiveSource _liveSource = PersonalLiveSource.fromDevices();
  bool _sourceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLiveSource();
  }

  Future<void> _loadLiveSource() async {
    final userId = context.read<GlobalState>().user?.id;
    var liveSource = PersonalLiveSource.fromDevices();
    if (userId != null) {
      try {
        liveSource = await loadDefaultPersonalLiveSource(userId);
      } catch (_) {
        // Use the empty source if persisted settings are unavailable.
      }
    }
    if (!mounted) return;
    setState(() {
      _liveSource = liveSource;
      _sourceLoaded = true;
    });
  }

  void _updateLiveSource(PersonalLiveSource liveSource) {
    setState(() => _liveSource = liveSource);
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
        leading: Icon(Icons.monitor_heart, size: 32.0, color: Colors.white),
        actions: [LogOutButton()],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              destinations: navigationDestinations,
              onDestinationSelected: (value) =>
                  setState(() => currentPage = indexToPersonalPage(value)),
            )
          : null,

      body: SafeArea(
        child: Row(
          children: [
            ?(!isMobile
                ? NavigationRail(
                    extended: true,
                    destinations: navigationRailDestinations,
                    onDestinationSelected: (value) => setState(
                      () => currentPage = indexToPersonalPage(value),
                    ),
                    selectedIndex: personalPageToIndex(currentPage),
                  )
                : null),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildContent() {
    switch (currentPage) {
      case .HomePage:
        if (!_sourceLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return PersonalHomePage(
          liveSource: _liveSource,
          onLiveSourceChanged: _updateLiveSource,
        );
      case .SummariesPage:
        return PersonalSummariesPage();
      case .MyCaretakers:
        return PersonalCaretakersPage();
      // case .History:
      //   return PersonalHistoryPage();
    }
    return null;
  }

  Widget? _buildFloatingActionButton() {
    return null;
  }
}
