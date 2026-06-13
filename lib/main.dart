import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'providers/providers.dart';
import 'screens/dump_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/search_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/reminders_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const SecondBrainApp(),
    ),
  );
}

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final itemId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => DetailScreen(itemId: itemId),
          );
        }
        return null;
      },
    );
  }
}

/// Main navigation shell with bottom nav bar
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _reminderCount = 0;

  final _screens = const [
    DumpScreen(),
    FeedScreen(),
    SearchScreen(),
    RemindersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadReminderCount();
  }

  Future<void> _loadReminderCount() async {
    try {
      final reminders = await ApiService.getPendingReminders();
      setState(() => _reminderCount = reminders.length);
    } catch (e) {
      print('Failed to load reminder count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(
              color: AppTheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 3) {
              _loadReminderCount();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.add_circle_outline, 0),
              activeIcon: _buildNavIcon(Icons.add_circle, 0, active: true),
              label: 'Dump',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.view_stream_outlined, 1),
              activeIcon: _buildNavIcon(Icons.view_stream, 1, active: true),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.search, 2),
              activeIcon: _buildNavIcon(Icons.search, 2, active: true),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _buildReminderIcon(3),
              activeIcon: _buildReminderIcon(3, active: true),
              label: 'Reminders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, {bool active = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        if (active)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildReminderIcon(int index, {bool active = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Icon(active ? Icons.notifications : Icons.notifications_outlined),
            if (_reminderCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _reminderCount > 99 ? '99+' : '$_reminderCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (active)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
