import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _roleSelection = 'citizen';

  void _login() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().setSelectedRole(_roleSelection);
      await context.read<AuthProvider>().login(
            _emailController.text,
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        final errorMsg = loc?.translate('loginFailed', params: {'error': e.toString()}) ??
            'Login failed: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => localeProvider.toggleLanguage(),
            icon: const Icon(Icons.language, color: Color(0xFF1E3A8A)),
            label: Text(
              localeProvider.isArabic ? 'English' : 'العربية',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 80, color: Color(0xFF1E3A8A)),
                const SizedBox(height: 24),
                Text(
                  loc?.translate('welcomeBack') ?? 'Welcome Back',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc?.translate('signInSub') ?? 'Sign in to your MoI account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Role Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _roleSelection = 'citizen'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _roleSelection == 'citizen'
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loc?.translate('citizen') ?? 'Citizen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _roleSelection == 'citizen'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _roleSelection = 'lawyer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _roleSelection == 'lawyer'
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Lawyer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _roleSelection == 'lawyer'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _roleSelection = 'officer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _roleSelection == 'officer'
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loc?.translate('officer') ?? 'Officer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _roleSelection == 'officer'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc?.translate('nationalId') ?? 'National ID Number',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? loc?.translate('pleaseEnterNationalId') ?? 'Please enter National ID'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: loc?.translate('password') ?? 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? loc?.translate('pleaseEnterPassword') ?? 'Please enter password'
                          : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed:
                      context.watch<AuthProvider>().isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: context.watch<AuthProvider>().isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          loc?.translate('login') ?? 'Login',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  ),
                  child: Text(
                    loc?.translate('noAccountRegister') ?? "Don't have an account? Register here",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
