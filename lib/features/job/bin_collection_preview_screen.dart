import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class BinCollectionPreviewScreen extends StatefulWidget {
  const BinCollectionPreviewScreen({super.key});

  @override
  State<BinCollectionPreviewScreen> createState() =>
      _BinCollectionPreviewScreenState();
}

class _BinCollectionPreviewScreenState extends State<BinCollectionPreviewScreen> {
  final List<BinItem> bins = [
    BinItem(
      number: '01',
      id: 'BIN-047',
      type: 'GLASS',
      weight: '~510kg',
      fillLevel: 0.85,
      isCollected: false,
    ),
    BinItem(
      number: '02',
      id: 'BIN-049',
      type: 'PAPER',
      weight: '~46kg',
      fillLevel: 0.78,
      isCollected: false,
    ),
    BinItem(
      number: '03',
      id: 'BIN-048',
      type: 'FOOD',
      weight: '~128kg',
      fillLevel: 0.40,
      isCollected: false,
      urgency: 'NOT URGENT',
    ),
  ];

  void _toggleBinCollection(int index) {
    setState(() {
      bins[index].isCollected = !bins[index].isCollected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'DRIVER #1024',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        actions: [
          const Icon(Icons.wifi, color: AppColors.accentBlue),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=1024'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentTeal, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStopInfo(),
                  _buildWeightWarning(),
                  ..._buildBinsList(),
                  _buildDoneButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStopInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stop 2 of 3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color(0xFF6E7482),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'CENTRAL MARKET',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Color(0xFF6E7482),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Central Market',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWeightWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4C1F1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB83C3C), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_outlined, color: Color(0xFFE87070), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEIGHT LIMIT WARNING',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Color(0xFFE87070),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stop exceeds typical load profile.\nStabilizers recommended.',
                  style: TextStyle(
                    color: Color(0xFFC9C9C9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  List<Widget> _buildBinsList() {
    return List.generate(bins.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildBinCard(index),
      );
    });
  }

  Widget _buildBinCard(int index) {
    final bin = bins[index];
    final progress = bin.fillLevel;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bin.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ ${bin.id}',
                          style: const TextStyle(
                            color: Color(0xFF6E7482),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF262A34),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            bin.type,
                            style: const TextStyle(
                              color: Color(0xFF9EA3AE),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bin.weight,
                          style: const TextStyle(
                            color: Color(0xFF6E7482),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (bin.urgency != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            bin.urgency!,
                            style: const TextStyle(
                              color: Color(0xFF6E7482),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'FILL LEVEL',
                      style: TextStyle(
                        color: Color(0xFF6E7482),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: const Color(0xFF2A2A2A),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleBinCollection(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, color: Color(0xFF6E7482), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SKIP',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Color(0xFF6E7482),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleBinCollection(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bin.isCollected
                          ? AppColors.accentGreen
                          : const Color(0xFF1B4D2E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          bin.isCollected ? Icons.check_circle : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COLLECTED',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(delay: (200 * (index + 1)).ms);
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          label: const Text(
            'DONE WITH THIS STOP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A4A4A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'HISTORY'),
        ],
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: Color(0xFF6E7482),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}

class BinItem {
  final String number;
  final String id;
  final String type;
  final String weight;
  final double fillLevel;
  bool isCollected;
  final String? urgency;

  BinItem({
    required this.number,
    required this.id,
    required this.type,
    required this.weight,
    required this.fillLevel,
    required this.isCollected,
    this.urgency,
  });
}
