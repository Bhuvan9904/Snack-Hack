import 'package:flutter/material.dart';
import 'package:snack_hack_app/features/groups/groups_screen.dart';
import 'package:snack_hack_app/features/spin/SpinScreen.dart';
import '../home/home_screen.dart';

import '../profile/profile_screen.dart';
import 'package:go_router/go_router.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  final GlobalKey<SpinScreenState> _spinKey = GlobalKey<SpinScreenState>();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      HomeScreen(key: _homeKey), // Index 0: Home
      SpinScreen(key: _spinKey), // Index 1: Spin
      GroupsScreen(), // Index 2: Groups
      ProfileScreen(), // Index 3: Profile
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];
    if (tabParam != null) {
      final tabIndex = int.tryParse(tabParam);
      if (tabIndex != null && tabIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = tabIndex;
        });
        if (tabIndex == 1) {
          final state = _spinKey.currentState;
          if (state is SpinScreenState) {
            state.refresh();
          }
        }
        if (tabIndex == 0) {
          final state = _homeKey.currentState;
          if (state is HomeScreenState) {
            state.refresh();
          }
        }
      }
    }
  }

  void _onItemTapped(int index) {
    print('🧭 NAV: Tab tapped - Index: $index');
    setState(() {
      _selectedIndex = index;
    });

    // Debug: Print which screen should be showing
    final screenNames = ['Home', 'Spin', 'Groups', 'Profile'];
    print('🧭 NAV: Should show screen: ${screenNames[index]}');

    if (index == 1) {
      // Refresh SpinScreen when tab is selected
      final state = _spinKey.currentState;
      if (state is SpinScreenState) {
        state.refresh();
      }
    }
    if (index == 0) {
      final state = _homeKey.currentState;
      if (state is HomeScreenState) {
        state.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(
          0xFF3CC45B,
        ), // Bright green for selected items
        unselectedItemColor: Colors.white70, // Light white for unselected items
        backgroundColor: const Color(0xFF3A3C51),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: 'Spin'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
