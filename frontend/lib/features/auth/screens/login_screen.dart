import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (success && mounted) {
      // Role-based redirect
      if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.eco, color: Colors.white, size: 44),
                              ),
                              const SizedBox(height: 16),
                              const Text('PlasticWatch',
                                  style: TextStyle(fontSize: 28,
                                      fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              const SizedBox(height: 4),
                              const Text('Monitor. Report. Act.',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        const Text('Welcome back',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Sign in to continue',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 24),

                        if (auth.error != null) ...[
                          ErrorBanner(message: auth.error!, onDismiss: auth.clearError),
                          const SizedBox(height: 16),
                        ],

                        AppTextField(
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 32),

                        AppButton(
                          label: 'Sign In',
                          isLoading: auth.isLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ",
                                style: TextStyle(color: AppTheme.textSecondary)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRouter.register),
                              child: const Text('Sign Up',
                                  style: TextStyle(color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        // Demo credentials hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Demo Credentials',
                                  style: TextStyle(fontWeight: FontWeight.w600,
                                      fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              _DemoCredential(
                                role: 'Admin',
                                email: 'admin@plasticwatch.com',
                                password: 'Admin@1234',
                                onTap: () {
                                  _emailCtrl.text = 'admin@plasticwatch.com';
                                  _passwordCtrl.text = 'Admin@1234';
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DemoCredential extends StatelessWidget {
  final String role;
  final String email;
  final String password;
  final VoidCallback onTap;

  const _DemoCredential({
    required this.role,
    required this.email,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(role,
                style: const TextStyle(color: AppTheme.primary,
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$email / $password',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ),
          const Icon(Icons.touch_app, size: 14, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
