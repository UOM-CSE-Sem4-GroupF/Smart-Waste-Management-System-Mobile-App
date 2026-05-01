import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../home/home_preview_screen.dart';

class LoginPreviewScreen extends StatefulWidget {
  const LoginPreviewScreen({super.key});

  @override
  State<LoginPreviewScreen> createState() => _LoginPreviewScreenState();
}

class _LoginPreviewScreenState extends State<LoginPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 24),
                Text(
                  'WasteCollect',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accentTeal, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DRIVER PORTAL',
                    style: TextStyle(
                      color: AppColors.accentTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(flex: 3),
                _buildLoginButton(),
                const SizedBox(height: 16),
                Text(
                  'Secure login via Keycloak SSO',
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(delay: 1000.ms),
                const Spacer(flex: 1),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final glow = _pulseController.value;
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCard,
            border: Border.all(
              color: AppColors.accentTeal.withOpacity(0.3 + glow * 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withOpacity(0.1 + glow * 0.2),
                blurRadius: 30 + glow * 20,
                spreadRadius: 5 + glow * 10,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '♻️',
              style: TextStyle(fontSize: 52),
            ),
          ),
        );
      },
    ).animate().scale(
          begin: const Offset(0.6, 0.6),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentTeal, Color(0xFF00A888)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 20),
              SizedBox(width: 10),
              Text(
                'Sign in with Keycloak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3);
  }
}
