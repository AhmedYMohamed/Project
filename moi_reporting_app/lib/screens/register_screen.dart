import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_switcher_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _syndicateIdController = TextEditingController();
  final _digitalSignatureController = TextEditingController();
  bool _isLawyer = false;

  void _register() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isLawyer) {
        await context.read<AuthProvider>().registerLawyer(
          email: _emailController.text,
          nationalId: _nationalIdController.text,
          password: _passwordController.text,
          syndicateId: _syndicateIdController.text,
          phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          digitalSignatureUrl: _digitalSignatureController.text.isNotEmpty ? _digitalSignatureController.text : null,
        );
      } else {
        await context.read<AuthProvider>().register(
          _emailController.text,
          _nationalIdController.text,
          _passwordController.text,
          phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.translate('registrationSuccess') ?? 'Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = loc?.translate('registrationFailed', params: {'error': e.toString()}) ??
            'Registration failed: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('register') ?? 'Register'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc?.translate('createAccount') ?? 'Create Account',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc?.translate('joinCommunity') ?? 'Join the community reporting system',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(loc?.translate('citizen') ?? 'Citizen'),
                    selected: !_isLawyer,
                    onSelected: (selected) {
                      if (selected) setState(() => _isLawyer = false);
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text(loc?.translate('lawyer') ?? 'Lawyer'),
                    selected: _isLawyer,
                    onSelected: (selected) {
                      if (selected) setState(() => _isLawyer = true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc?.translate('email') ?? 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? loc?.translate('pleaseEnterEmail') ?? 'Please enter email'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalIdController,
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
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: loc?.translate('phoneOptional') ?? 'Phone Number (Optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              if (_isLawyer) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _syndicateIdController,
                  decoration: InputDecoration(
                    labelText: loc?.translate('syndicateIdBarId') ?? 'Syndicate ID / Bar ID',
                    prefixIcon: const Icon(Icons.gavel),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? (loc?.translate('pleaseEnterSyndicateId') ?? 'Please enter Syndicate ID')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _digitalSignatureController,
                  decoration: InputDecoration(
                    labelText: loc?.translate('digitalSignatureUrl') ?? 'Digital Signature URL (Optional)',
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc?.translate('password') ?? 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) => value != null && value.length < 6
                    ? loc?.translate('passwordTooShort') ?? 'Password too short'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: context.watch<AuthProvider>().isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: context.watch<AuthProvider>().isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc?.translate('register') ?? 'Register', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
