import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
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

  Future<void> _onLogin() async {
    final keycloak = ref.read(keycloakServiceProvider.notifier);
    await keycloak.login();
    if (!mounted) return;
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (isLoggedIn) {
      context.go('/home');
    } else {
      final err = ref.read(authStateProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo section
                _buildLogo(),
                const SizedBox(height: 24),
                // App name
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
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
                // Login button
                _buildLoginButton(authState.isLoading),
                const SizedBox(height: 16),
                // Info text
                Text(
                  'Secure login via Keycloak SSO',
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(delay: 1000.ms),
                const Spacer(flex: 1),
                // Version
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
              color: AppColors.accentTeal.withValues(alpha: 0.3 + glow * 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withValues(alpha: 0.1 + glow * 0.2),
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

  Widget _buildLoginButton(bool isLoading) {
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
              color: AppColors.accentTeal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : const Row(
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
