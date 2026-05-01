import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'home_preview_screen.dart';

class PreviewShell extends StatefulWidget {
  const PreviewShell({super.key});

  @override
  State<PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<PreviewShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePreviewBody(),
    const MapPreviewBody(),
    const HistoryPreviewBody(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.bgPrimary,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textMuted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'MAP'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'HISTORY'),
          ],
        ),
      ),
    );
  }
}

class MapPreviewBody extends StatelessWidget {
  const MapPreviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://api.placeholder.com/1200/800?text=Full+Map+View'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.4)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zone 3 - Real-time Map',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: AppColors.accentGreen, size: 10),
                      SizedBox(width: 8),
                      Text('8 Active Vehicles', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryPreviewBody extends StatelessWidget {
  const HistoryPreviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job History',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: AppColors.accentBlue, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Job #82$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Oct 2${5-index}, 2023 • 12 Bins', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Text('1,240 kg', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
