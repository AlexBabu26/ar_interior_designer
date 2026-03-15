import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme_provider.dart';
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
          child: Icon(auth.isAuthenticated ? Icons.person : Icons.login),
        ),
      ),
    );
  }
}

enum _AuthMenuAction { login, register, account, admin, logout }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return _AuthScaffold(
      title: 'Login',
      subtitle:
          'Sign in with your email to continue to checkout and account tools.',
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
      title: 'Register',
      subtitle:
          'Create a customer account. Admin access is assigned separately.',
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
      title: 'Forgot Password',
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
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Email'),
              subtitle: Text(auth.currentUser?.email ?? 'Unknown'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Display name'),
              subtitle: Text(profile?.displayName ?? 'Not set'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Role'),
              subtitle: Text(profile?.role.value ?? 'customer'),
            ),
          ),
          if (auth.isAdmin) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open admin dashboard'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
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
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
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
        padding: const EdgeInsets.all(24),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Product management'),
              subtitle: Text(
                'Phase 1 unlocks the protected admin entry point.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.analytics_outlined),
              title: Text('Analytics dashboard'),
              subtitle: Text('Planned for a later phase of the roadmap.'),
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
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
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
