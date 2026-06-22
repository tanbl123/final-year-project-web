import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer/features/auth/services/account_service.dart';
import 'package:customer/features/auth/state/auth_provider.dart';

/// Customer self-service sign-up. On success the account is created and we log
/// the customer straight in, then pop back.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  // per-field inline errors
  String? _fullNameError;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    for (final c in [_fullName, _username, _email, _phone, _address, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _fullNameError = _fullName.text.trim().isEmpty ? 'Full name is required.' : null;
      _usernameError = _username.text.trim().isEmpty ? 'Username is required.' : null;
      _emailError = _email.text.trim().isEmpty ? 'Email is required.' : null;
      _phoneError = _phone.text.trim().isEmpty ? 'Phone number is required.' : null;
      _passwordError = _password.text.isEmpty ? 'Password is required.' : null;
      _confirmError = (_password.text.isNotEmpty && _password.text != _confirm.text)
          ? 'Passwords do not match.'
          : null;
    });
    if (_fullNameError != null ||
        _usernameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AccountService>().registerCustomer(
            username: _username.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phoneNumber: _phone.text.trim(),
            shippingAddress: _address.text.trim(),
          );
      // created — log straight in with the new credentials
      await context.read<AuthProvider>().login(_username.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // route the server error to the most likely field, else under the password
      final msg = e.toString();
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('username')) {
          _usernameError = msg;
        } else if (lower.contains('email')) {
          _emailError = msg;
        } else if (lower.contains('password')) {
          _passwordError = msg;
        } else {
          _passwordError = msg;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_fullName, 'Full name',
              errorText: _fullNameError, onChanged: () => setState(() => _fullNameError = null)),
          _field(_username, 'Username',
              errorText: _usernameError, onChanged: () => setState(() => _usernameError = null)),
          _field(_email, 'Email',
              keyboard: TextInputType.emailAddress,
              errorText: _emailError, onChanged: () => setState(() => _emailError = null)),
          _field(_phone, 'Phone number',
              keyboard: TextInputType.phone,
              errorText: _phoneError, onChanged: () => setState(() => _phoneError = null)),
          _field(_address, 'Shipping address (optional)', maxLines: 2),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: _passwordError == null ? null : (_) => setState(() => _passwordError = null),
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              helperText: '8+ chars with upper, lower, number & symbol',
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            onChanged: _confirmError == null ? null : (_) => setState(() => _confirmError = null),
            decoration: InputDecoration(
              labelText: 'Confirm password',
              border: const OutlineInputBorder(),
              errorText: _confirmError,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
          {TextInputType? keyboard, int maxLines = 1, String? errorText, VoidCallback? onChanged}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          keyboardType: keyboard,
          maxLines: maxLines,
          onChanged: (errorText == null || onChanged == null) ? null : (_) => onChanged(),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: errorText,
          ),
        ),
      );
}
