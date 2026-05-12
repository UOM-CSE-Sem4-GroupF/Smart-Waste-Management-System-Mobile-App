import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _regController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;

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
    _regController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // Completely bypass Keycloak login for now
    // final keycloak = ref.read(keycloakServiceProvider.notifier);
    // await keycloak.login();
    
    if (!mounted) return;
    ref.read(isLoggedInProvider.notifier).state = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bg = isDark ? AppColors.bgPrimary : const Color(0xFFF0F4F8);
    final cardBg = isDark ? AppColors.bgCard : Colors.white;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0F1117);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF4B5563);
    final dividerColor =
        isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F1117), const Color(0xFF0D1520)]
                    : [const Color(0xFFF0F4F8), const Color(0xFFE8F5F2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Theme toggle — top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: _buildThemeToggle(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // ── Logo ────────────────────────────────────────────────
                  _buildLogo(isDark),
                  const SizedBox(height: 20),
                  // ── App name ─────────────────────────────────────────────
                  Text(
                    'WasteCollect',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.accentTeal, width: 1.5),
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
                  const SizedBox(height: 40),
                  // ── Login card ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your credentials to continue',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 28),
                        // Driver Registration Number field
                        _buildLabel('Driver Registration Number', isDark),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _regController,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : const Color(0xFF0F1117),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. DRV-1024',
                            prefixIcon: Icon(Icons.badge_outlined,
                                color: AppColors.accentTeal, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        _buildLabel('Password', isDark),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : const Color(0xFF0F1117),
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.accentTeal,
                                size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark
                                    ? AppColors.textMuted
                                    : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildLoginButton(authState.isLoading),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.15),
                  const SizedBox(height: 24),
                  Text(
                    'Secure login via Keycloak SSO',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: textSecondary),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMuted
                              : const Color(0xFF9CA3AF),
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textSecondary : const Color(0xFF374151),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);
        final isDarkLocal = themeMode == ThemeMode.dark;
        return GestureDetector(
          onTap: () {
            ref.read(themeModeProvider.notifier).state =
                isDarkLocal ? ThemeMode.light : ThemeMode.dark;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkLocal ? AppColors.bgCardLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkLocal
                    ? AppColors.divider
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isDarkLocal
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: isDarkLocal
                  ? AppColors.accentYellow
                  : const Color(0xFF6366F1),
              size: 22,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final glow = _pulseController.value;
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.bgCard : Colors.white,
            border: Border.all(
              color: AppColors.accentTeal.withValues(alpha: 0.3 + glow * 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.accentTeal.withValues(alpha: 0.1 + glow * 0.2),
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
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentTeal, Color(0xFF00A888)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
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
              borderRadius: BorderRadius.circular(14),
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
                    Icon(Icons.login_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sign In',
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
