import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../itinerary/screens/itinerary_screen.dart';
import '../../map/screens/map_radar_screen.dart';
import '../../places/screens/search_places_screen.dart';
import '../../tips/screens/tips_screen.dart';
import '../../places/providers/shared_link_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  final List<Widget> _screens = const [
    ItineraryScreen(),
    MapRadarScreen(),
    SearchPlacesScreen(),
    TipsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ReceiveSharingIntent.instance.getInitialMedia().then(_receiveShared);
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _receiveShared,
    );
  }

  void _receiveShared(List<SharedMediaFile> files) {
    final link = files
        .map((file) => file.path)
        .firstWhere((value) => value.startsWith('http'), orElse: () => '');
    if (link.isNotEmpty) {
      ref.read(sharedLinkProvider.notifier).setLink(link);
      setState(() => _currentIndex = 0);
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    ReceiveSharingIntent.instance.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Itinerary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map Radar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(Icons.manage_search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline_rounded),
            activeIcon: Icon(Icons.lightbulb_rounded),
            label: 'Tips',
          ),
        ],
      ),
    );
  }
}
