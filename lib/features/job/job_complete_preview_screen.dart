import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../home/preview_shell.dart';

class JobCompletePreviewScreen extends ConsumerWidget {
  const JobCompletePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          const Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=1024'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Success Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentBlue,
                    size: 60,
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              ),
              const SizedBox(height: 32),
              const Text(
                'Job Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              const Text(
                'Route finalized and verified successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 48),
              
              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard('BINS COLLECTED', '11', Icons.recycling, Colors.blue),
                  _buildStatCard('BINS SKIPPED', '1', Icons.error_outline, Colors.redAccent),
                  _buildStatCard('TOTAL WEIGHT', '631 kg', Icons.scale_outlined, Colors.white70),
                  _buildStatCard('DURATION', '44 min', Icons.timer_outlined, Colors.white70),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 24),
              
              // Blockchain TX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub_outlined, color: Colors.white54, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BLOCKCHAIN TX',
                            style: TextStyle(
                              color: Color(0xFF6E7482),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'a3f7...cc12',
                            style: TextStyle(
                              color: AppColors.accentBlue.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 48),
              
              // Buttons
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(previewIndexProvider.notifier).state = 1; // Map index
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('VIEW ON MAP'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.white24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(previewIndexProvider.notifier).state = 0; // Home index
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF4A89FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ).animate().fadeIn(delay: 1100.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6E7482),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
