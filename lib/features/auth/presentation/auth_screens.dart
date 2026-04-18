import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../application/auth_provider.dart';
import '../../admin/presentation/admin_inventory_screen.dart';
import '../../modifications/data/modification_repository.dart';
import '../../modifications/domain/furniture_modification.dart';


class AuthMenuButton extends StatelessWidget {
  const AuthMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final avatar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: (() {
          if (!auth.isAuthenticated) return const Icon(Icons.login);
          final name = auth.profile?.displayName ?? auth.currentUser?.email ?? '';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          return Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        })(),
      ),
    );

    if (auth.isAuthenticated) {
      return InkWell(
        onTap: () => showAccountModal(context),
        borderRadius: BorderRadius.circular(20),
        child: avatar,
      );
    }

    return PopupMenuButton<_AuthMenuAction>(
      tooltip: 'Sign in',
      onSelected: (action) {
        if (action == _AuthMenuAction.login) {
          context.push('/login');
        } else if (action == _AuthMenuAction.register) {
          context.push('/register');
        }
      },
      itemBuilder: (context) {
        return const <PopupMenuEntry<_AuthMenuAction>>[
          PopupMenuItem(value: _AuthMenuAction.login, child: Text('Login')),
          PopupMenuItem(
            value: _AuthMenuAction.register,
            child: Text('Register'),
          ),
        ];
      },
      child: avatar,
    );
  }
}

enum _AuthMenuAction { login, register, account, generations, admin, carpenter, logout }

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
  bool _obscurePassword = true;

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
      context.go(_resolvedRedirect(widget.redirectTo, '/'));
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
      subtitle: '',
      hideIntro: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your account to continue.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.deepUmber,
                  ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.deepUmber,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
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
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.burntSienna,
                    AppTheme.burntSienna.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burntSienna.withAlpha(75),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  auth.isBusy ? 'Signing in...' : 'Login',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
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
                        path: '/signup',
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

    if (!mounted) return;

    // Show success popup
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.parchmentHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Success!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        content: Text(
          auth.infoMessage ?? 'Your account has been successfully created.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.richCharcoal,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (auth.isAuthenticated) {
      context.go(_resolvedRedirect(widget.redirectTo, '/'));
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
      subtitle: '',
      hideIntro: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create your account',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your journey with us today.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.deepUmber,
                  ),
            ),
            const SizedBox(height: 32),
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
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.deepUmber,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Use at least 6 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.deepUmber,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.burntSienna,
                    AppTheme.burntSienna.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burntSienna.withAlpha(75),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  auth.isBusy ? 'Creating account...' : 'Register',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/login',
                    queryParameters: _redirectQuery(widget.redirectTo),
                  ).toString(),
                ),
                child: const Text('Already have an account? Login'),
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
      subtitle: '',
      hideIntro: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset your password',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email to receive recovery instructions.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.deepUmber,
                  ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.burntSienna,
                    AppTheme.burntSienna.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burntSienna.withAlpha(75),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  auth.isBusy ? 'Sending...' : 'Send reset link',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to login'),
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

/// Call this to open the account overview as a modal (e.g. from the app bar menu).
void showAccountModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
    ),
    builder: (modalContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(modalContext).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(modalContext).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    AccountContent(
                      onNavigateAway: () =>
                          Navigator.of(modalContext).pop(),
                      parentContext: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: ListView(
        children: [
          AppPageWidth(
            child: AccountContent(),
          ),
        ],
      ),
    );
  }
}

/// Reusable account overview content (profile, links, logout).
/// Used in full AccountScreen and in the account modal.
class AccountContent extends StatelessWidget {
  const AccountContent({
    super.key,
    this.onNavigateAway,
    this.parentContext,
  });

  /// When set (e.g. in modal), call before navigating so the sheet closes first.
  final VoidCallback? onNavigateAway;
  final BuildContext? parentContext;

  void _navigate(BuildContext context, String path) {
    if (parentContext != null && parentContext!.mounted) {
      onNavigateAway?.call();
      GoRouter.of(parentContext!).push(path);
    } else {
      context.push(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Profile header ─────────────────────────────────
        Center(
          child: AppPanel(
            child: Row(
              children: [
                (() {
                  final name = profile?.displayName ?? auth.currentUser?.email ?? '';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.parchment,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.burntSienna,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  );
                })(),
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
        ),
        const SizedBox(height: 18),

        // ── Info tiles ────────────────────────────────────
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

        const SizedBox(height: 28),

        // ── Action tiles (centered column) ────────────────
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                if (!auth.isCarpenter && !auth.isAdmin) ...[
                  _AccountOptionTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppTheme.burntSienna,
                    title: 'Purchase History',
                    subtitle: 'View all your past orders',
                    onTap: () => _navigate(context, '/account/purchases'),
                  ),
                  const SizedBox(height: 12),
                  _AccountOptionTile(
                    icon: Icons.auto_awesome_outlined,
                    iconColor: const Color(0xFF7B5EA7),
                    title: 'Image History',
                    subtitle: 'AI-generated room images',
                    onTap: () => _navigate(context, '/account/generations'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!auth.isCarpenter && !auth.isAdmin)
                  _AccountOptionTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF2E86AB),
                    title: 'My Modification Requests',
                    subtitle: 'View and manage room modification chats',
                    onTap: () => _navigate(context, '/account/modifications'),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Logout (centered, red) ─────────────────────────
        Center(
          child: SizedBox(
            width: 200,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final didSignOut = await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  if (didSignOut) {
                    onNavigateAway?.call();
                    final ctx = parentContext ?? context;
                    if (ctx.mounted) GoRouter.of(ctx).go('/');
                  } else {
                    _showSnackBar(
                      context,
                      context.read<AuthProvider>().errorMessage ??
                          'Unable to sign out right now.',
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminName = 'Admin';
    final orderRepo = context.read<OrderRepository>();
    final productRepo = context.read<ProductRepository>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header with greeting + quick stats ──────────
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.burntSienna.withAlpha(140),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withAlpha(60), width: 1),
                    ),
                  ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // back + title row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Admin Panel',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const Spacer(),
                          const AuthMenuButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // greeting
                      Text(
                        'Welcome back,',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.white54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        adminName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 28),
                      // live stats row
                      FutureBuilder<({int orders, double revenue, int products})>(
                        future: Future.wait([
                          orderRepo.getOrders(),
                          productRepo.getAdminProducts(),
                        ]).then((r) {
                          final orders = r[0] as List<Order>;
                          final prods = r[1] as List<Product>;
                          return (
                            orders: orders.length,
                            revenue: orders.fold<double>(0, (s, o) => s + o.total),
                            products: prods.length,
                          );
                        }),
                        builder: (context, snap) {
                          final loading = snap.connectionState == ConnectionState.waiting;
                          final orders = snap.data?.orders ?? 0;
                          final revenue = snap.data?.revenue ?? 0;
                          final products = snap.data?.products ?? 0;
                          return Row(
                            children: [
                              _StatPill(
                                label: 'Orders',
                                value: loading ? '—' : '$orders',
                                icon: Icons.receipt_long_outlined,
                              ),
                              const SizedBox(width: 10),
                              _StatPill(
                                label: 'Revenue',
                                value: loading ? '—' : formatCurrency(revenue),
                                icon: Icons.attach_money_rounded,
                              ),
                              const SizedBox(width: 10),
                              _StatPill(
                                label: 'Products',
                                value: loading ? '—' : '$products',
                                icon: Icons.inventory_2_outlined,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

          // ── Action cards ─────────────────────────────────────
          SliverToBoxAdapter(
            child: AppPageWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    'Manage',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.8,
                          color: AppTheme.burntSienna,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _AdminActionCard(
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF6B8F71),
                    title: 'Product Management',
                    description:
                        'Add new furniture, edit details, upload 3D models, and toggle product visibility.',
                    badge: 'Catalogue',
                    onTap: () => context.push('/admin/products'),
                  ),
                  const SizedBox(height: 14),
                  _AdminActionCard(
                    icon: Icons.inventory_rounded,
                    iconColor: const Color(0xFFE2B45C),
                    title: 'Stock Management',
                    description:
                        'Quickly adjust product quantities, monitor low stock alerts, and manage incoming inventory.',
                    badge: 'Live Stock',
                    onTap: () => context.push('/admin/inventory'),
                  ),
                  const SizedBox(height: 14),
                  _AdminActionCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF2E86AB),
                    title: 'Analytics Dashboard',
                    description:
                        'Track total orders, revenue trends, and recent transaction activity.',
                    badge: 'Insights',
                    onTap: () => context.push('/admin/analytics'),
                  ),
                  const SizedBox(height: 14),
                  _AdminActionCard(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF7B5EA7),
                    title: 'Modification Chats',
                    description:
                        'Oversee all customer–carpenter modification request threads.',
                    badge: 'Support',
                    onTap: () => context.push('/admin/modifications'),
                  ),
                  const SizedBox(height: 14),
                  _AdminActionCard(
                    icon: Icons.person_add_rounded,
                    iconColor: AppTheme.burntSienna,
                    title: 'Create Carpenter Account',
                    description:
                        'Register a new carpenter user who can accept and fulfil modification requests.',
                    badge: 'Users',
                    onTap: () => context.push('/admin/create-carpenter'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat pill widget inside the dark header ───────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.burntSienna, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rich action card ──────────────────────────────────────────
class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AppPanel(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.deepUmber,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.deepUmber.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarpenterDashboardScreen extends StatelessWidget {
  const CarpenterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.displayName ?? auth.currentUser?.email ?? 'Carpenter';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header with greeting ──────────
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8F71).withAlpha(140),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withAlpha(60), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Carpenter Portal',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const Spacer(),
                              const AuthMenuButton(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome back,',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Action cards ─────────────────────────────────────
          SliverToBoxAdapter(
            child: AppPageWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Your Workspace',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.8,
                            color: const Color(0xFF6B8F71),
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<FurnitureModification>>(
                    future: context.read<ModificationRepository>().listModifications(),
                    builder: (context, snap) {
                      final list = snap.data ?? [];
                      final activeCount = list.where((m) {
                        final isPast = m.status == 'completed' || m.status == 'cancelled';
                        final isDraft = m.status == 'pending_order';
                        return !isPast && !isDraft;
                      }).length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _AdminActionCard(
                          icon: Icons.chat_bubble_rounded,
                          iconColor: const Color(0xFF7B5EA7),
                          title: 'Active Requests',
                          description:
                              'View and respond to client furniture modification requests and custom orders.',
                          badge: activeCount > 0 ? '$activeCount Active' : 'Active Tasks',
                          onTap: () => context.push(
                            Uri(path: '/account/modifications', queryParameters: {'history': 'false'}).toString(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _AdminActionCard(
                      icon: Icons.history_rounded,
                      iconColor: const Color(0xFF2E86AB),
                      title: 'Past Requests',
                      description:
                          'Review successfully completed or cancelled modification projects.',
                      badge: 'History',
                      onTap: () => context.push(
                        Uri(path: '/account/modifications', queryParameters: {'history': 'true'}).toString(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
    this.backgroundImage,
    this.hideIntro = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? backgroundImage;
  final bool hideIntro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppTheme.richCharcoal,
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (backgroundImage != null)
            Positioned.fill(
              child: Image.asset(backgroundImage!, fit: BoxFit.cover),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.parchmentHighlight,
                      AppTheme.parchment,
                      AppTheme.mutedClay,
                    ],
                  ),
                ),
              ),
            ),
          ListView(
            children: [
              AppPageWidth(
                maxWidth: 1120,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (hideIntro) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: AppGlassyPanel(child: child),
                        ),
                      );
                    }

                    final isWide = constraints.maxWidth >= 860;
                    final introPanel = AppGlassyPanel(
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

                    final formPanel = AppGlassyPanel(child: child);

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

class _AccountOptionTile extends StatelessWidget {
  const _AccountOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.deepUmber,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.deepUmber.withAlpha(140),
            ),
          ],
        ),
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
