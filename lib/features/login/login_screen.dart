import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _driverIdCtrl = TextEditingController();

  @override
  void dispose() {
    _unitCtrl.dispose();
    _driverIdCtrl.dispose();
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
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    // Theme colors matching the design
    const Color cyan = Color(0xFF00E5FF);
    const Color bgDark = Color(0xFF111111);
    const Color bgBox = Color(0xFF161616);
    const Color bgInput = Color(0xFF181818);
    const Color borderGray = Color(0xFF2A2A2A);
    const Color textMuted = Color(0xFF7A7A7A);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Icon Box
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: cyan, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_shipping_outlined, color: cyan, size: 36),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titles
                const Text(
                  'WASTECOLLECT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cyan,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DRIVER PORTAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgDark,
                    border: Border.all(color: borderGray, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UNIT NUMBER',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _unitCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'E.G. 402',
                          hintStyle: const TextStyle(color: Color(0xFF444444)),
                          filled: true,
                          fillColor: bgInput,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: borderGray, width: 1.5),
                            borderRadius: BorderRadius.zero,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: cyan, width: 1.5),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'DRIVER ID',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _driverIdCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '........',
                          hintStyle: const TextStyle(color: Color(0xFF444444)),
                          filled: true,
                          fillColor: bgInput,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: borderGray, width: 1.5),
                            borderRadius: BorderRadius.zero,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: cyan, width: 1.5),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Security Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgBox,
                          border: Border.all(color: borderGray, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.security_outlined, color: textMuted, size: 18),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'SECURE INDUSTRIAL LOGIN PROTOCOL ACTIVE. UNAUTHORIZED ACCESS ATTEMPTS ARE LOGGED.',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Log in button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: authState.isLoading ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cyan,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          icon: authState.isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.key_outlined, size: 20),
                          label: const Text(
                            'LOG IN',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Support button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: borderGray, width: 1.5),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          icon: const Icon(Icons.help_outline, size: 20),
                          label: const Text(
                            'SUPPORT',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bottom Truck Image Mock (gradient)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: borderGray, width: 1.5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Center(
                        child: Icon(Icons.fire_truck_rounded, color: borderGray, size: 48),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, bgDark],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Footer
                const Text(
                  'VERSION 1.0.0 © 2024 SMART WASTE MANAGEMENT',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
