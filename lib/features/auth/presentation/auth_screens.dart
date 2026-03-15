import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../application/auth_provider.dart';

class AuthMenuButton extends StatelessWidget {
  const AuthMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopupMenuButton<_AuthMenuAction>(
      tooltip: auth.isAuthenticated ? 'Account menu' : 'Sign in',
      onSelected: (action) async {
        switch (action) {
          case _AuthMenuAction.login:
            context.push('/login');
            break;
          case _AuthMenuAction.register:
            context.push('/register');
            break;
          case _AuthMenuAction.account:
            context.push('/account');
            break;
          case _AuthMenuAction.generations:
            context.push('/account/generations');
            break;
          case _AuthMenuAction.admin:
            context.push('/admin');
            break;
          case _AuthMenuAction.logout:
            final didSignOut = await context.read<AuthProvider>().signOut();
            if (context.mounted) {
              if (didSignOut) {
                context.go('/');
              } else {
                _showSnackBar(
                  context,
                  context.read<AuthProvider>().errorMessage ??
                      'Unable to sign out right now.',
                );
              }
            }
            break;
        }
      },
      itemBuilder: (context) {
        if (!auth.isAuthenticated) {
          return const <PopupMenuEntry<_AuthMenuAction>>[
            PopupMenuItem(value: _AuthMenuAction.login, child: Text('Login')),
            PopupMenuItem(
              value: _AuthMenuAction.register,
              child: Text('Register'),
            ),
          ];
        }

        return <PopupMenuEntry<_AuthMenuAction>>[
          const PopupMenuItem(
            value: _AuthMenuAction.account,
            child: Text('Account'),
          ),
          const PopupMenuItem(
            value: _AuthMenuAction.generations,
            child: Text('Image history'),
          ),
          if (auth.isAdmin)
            const PopupMenuItem(
              value: _AuthMenuAction.admin,
              child: Text('Admin'),
            ),
          const PopupMenuItem(
            value: _AuthMenuAction.logout,
            child: Text('Logout'),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Icon(auth.isAuthenticated ? Icons.person : Icons.login),
        ),
      ),
    );
  }
}

enum _AuthMenuAction { login, register, account, generations, admin, logout }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectTo, this.message});

  final String? redirectTo;
  final String? message;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final didSignIn = await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (didSignIn) {
      context.go(_resolvedRedirect(widget.redirectTo, '/account'));
      return;
    }

    _showMessage(auth.errorMessage ?? 'Unable to sign in.');
  }

  Future<void> _resendVerificationEmail() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    final auth = context.read<AuthProvider>();
    final didResend = await auth.resendVerificationEmail(
      email: _emailController.text,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      didResend
          ? auth.infoMessage ??
                'If that account is waiting for verification, a new verification email has been sent.'
          : auth.errorMessage ?? 'Unable to resend the verification email.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return _AuthScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in to manage purchases, move faster through checkout, and keep your shortlist close at hand.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 24),
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.isBusy ? null : _submit,
                child: Text(auth.isBusy ? 'Signing in...' : 'Login'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(
                Uri(
                  path: '/forgot-password',
                  queryParameters: _redirectQuery(widget.redirectTo),
                ).toString(),
              ),
              child: const Text('Forgot password?'),
            ),
            TextButton(
              onPressed: () => context.push(
                Uri(
                  path: '/register',
                  queryParameters: _redirectQuery(widget.redirectTo),
                ).toString(),
              ),
              child: const Text('Create an account'),
            ),
            TextButton(
              onPressed: auth.isBusy ? null : _resendVerificationEmail,
              child: const Text('Resend verification email'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final didRegister = await auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
    );

    if (!mounted) {
      return;
    }

    if (!didRegister) {
      _showMessage(auth.errorMessage ?? 'Unable to register.');
      return;
    }

    _showMessage(auth.infoMessage ?? 'Account created successfully.');

    if (auth.isAuthenticated) {
      context.go(_resolvedRedirect(widget.redirectTo, '/account'));
      return;
    }

    context.go(
      Uri(
        path: '/login',
        queryParameters: _redirectQuery(widget.redirectTo),
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return _AuthScaffold(
      title: 'Create your account',
      subtitle:
          'Start a customer account for checkout, purchase history, and a calmer furniture shopping flow.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.isBusy ? null : _submit,
                child: Text(auth.isBusy ? 'Creating account...' : 'Register'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(
                Uri(
                  path: '/login',
                  queryParameters: _redirectQuery(widget.redirectTo),
                ).toString(),
              ),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final didSend = await auth.sendPasswordResetEmail(
      email: _emailController.text,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      didSend
          ? auth.infoMessage ?? 'Reset instructions sent.'
          : auth.errorMessage ?? 'Unable to send reset email.',
    );

    if (didSend) {
      context.go(
        Uri(
          path: '/login',
          queryParameters: _redirectQuery(widget.redirectTo),
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return _AuthScaffold(
      title: 'Reset your password',
      subtitle:
          'Enter your email and we will send reset instructions if the account exists.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.isBusy ? null : _submit,
                child: Text(auth.isBusy ? 'Sending...' : 'Send reset link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  eyebrow: 'Account',
                  title: 'Account overview',
                  subtitle:
                      'Profile details, order history, and account actions are gathered here in one calm workspace.',
                ),
                const SizedBox(height: 24),
                AppPanel(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.parchment,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.person_outline, size: 32),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.displayName ?? 'Guest account',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              auth.currentUser?.email ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _AccountInfoTile(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: auth.currentUser?.email ?? 'Unknown',
                ),
                const SizedBox(height: 14),
                _AccountInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Display name',
                  value: profile?.displayName ?? 'Not set',
                ),
                const SizedBox(height: 14),
                _AccountInfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Role',
                  value: profile?.role.value ?? 'customer',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/account/purchases'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('View purchase history'),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => context.push('/account/generations'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Image history'),
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Open admin dashboard'),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final didSignOut = await context
                        .read<AuthProvider>()
                        .signOut();
                    if (context.mounted) {
                      if (didSignOut) {
                        context.go('/');
                      } else {
                        _showSnackBar(
                          context,
                          context.read<AuthProvider>().errorMessage ??
                              'Unable to sign out right now.',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  eyebrow: 'Admin workspace',
                  title: 'Control the collection',
                  subtitle:
                      'Keep product data accurate and maintain the same premium brand language without losing operational clarity.',
                ),
                const SizedBox(height: 24),
                AppPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Product management'),
                    subtitle: const Text(
                      'Create, update, and control which products are active in the storefront.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/products'),
                  ),
                ),
                const SizedBox(height: 14),
                const AppPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Transactions and analytics'),
                    subtitle: Text(
                      'Order reporting and analytics are still planned for a later phase.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppPageWidth(
          maxWidth: 520,
          child: AppPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  redirectTo == null
                      ? 'Checking your session...'
                      : 'Checking access for $redirectTo...',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account access')),
      body: ListView(
        children: [
          AppPageWidth(
            maxWidth: 1120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final introPanel = AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.burntSienna,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.deepUmber,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _AuthFeatureRow(
                        icon: Icons.shopping_bag_outlined,
                        text: 'Checkout with less friction',
                      ),
                      const SizedBox(height: 12),
                      const _AuthFeatureRow(
                        icon: Icons.receipt_long_outlined,
                        text: 'Keep every purchase in one history view',
                      ),
                      const SizedBox(height: 12),
                      const _AuthFeatureRow(
                        icon: Icons.view_in_ar_outlined,
                        text: 'Move between catalog, product detail, and AR',
                      ),
                    ],
                  ),
                );

                final formPanel = AppPanel(child: child);

                if (!isWide) {
                  return Column(
                    children: [
                      introPanel,
                      const SizedBox(height: 18),
                      formPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: introPanel),
                    const SizedBox(width: 20),
                    Expanded(flex: 5, child: formPanel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

class _AuthFeatureRow extends StatelessWidget {
  const _AuthFeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Enter your email';
  }
  if (!email.contains('@')) {
    return 'Enter a valid email address';
  }
  return null;
}

Map<String, String>? _redirectQuery(String? redirectTo) {
  if (redirectTo == null || redirectTo.isEmpty) {
    return null;
  }

  return <String, String>{'from': redirectTo};
}

String _resolvedRedirect(String? redirectTo, String fallback) {
  if (redirectTo == null || redirectTo.isEmpty) {
    return fallback;
  }

  return redirectTo;
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
