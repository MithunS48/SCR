import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailCtrl        = TextEditingController();
  final _displayNameCtrl  = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  bool _obscurePassword   = true;
  String _selectedRole    = 'USER';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailCtrl.text.trim(),
      displayName: _displayNameCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
    );
    if (success && mounted) {
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
      appBar: AppBar(title: const Text('Create Account')),
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
                        const Text('Join PlasticWatch',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Create your account to start tracking',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 24),

                        if (auth.error != null) ...[
                          ErrorBanner(
                              message: auth.error!,
                              onDismiss: auth.clearError),
                          const SizedBox(height: 16),
                        ],

                        // Display name
                        AppTextField(
                          label: 'Display Name',
                          controller: _displayNameCtrl,
                          prefixIcon: const Icon(Icons.person_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Display name is required';
                            if (v.length < 2) return 'Must be at least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
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

                        // Password
                        AppTextField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8)
                              return 'Password must be at least 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Role selector
                        const Text('Account Type',
                            style: TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                role: 'USER',
                                title: 'Regular User',
                                subtitle: 'Track usage, report waste, join events',
                                icon: Icons.person_outlined,
                                color: AppTheme.primary,
                                isSelected: _selectedRole == 'USER',
                                onTap: () => setState(() => _selectedRole = 'USER'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                role: 'ADMIN',
                                title: 'Administrator',
                                subtitle: 'Moderate reports, manage content',
                                icon: Icons.admin_panel_settings_outlined,
                                color: Colors.deepPurple,
                                isSelected: _selectedRole == 'ADMIN',
                                onTap: () => setState(() => _selectedRole = 'ADMIN'),
                              ),
                            ),
                          ],
                        ),

                        // Admin warning
                        if (_selectedRole == 'ADMIN') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.amber, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Admin accounts can only be created by '
                                    'an existing administrator.',
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        AppButton(
                          label: 'Create Account',
                          isLoading: auth.isLoading,
                          onPressed: _register,
                          color: _selectedRole == 'ADMIN'
                              ? Colors.deepPurple
                              : AppTheme.primary,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ',
                                style: TextStyle(color: AppTheme.textSecondary)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Sign In',
                                  style: TextStyle(color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
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

/// Role selection card widget.
class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.15),
                           blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? color : AppTheme.textPrimary,
                )),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}
