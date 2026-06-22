import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:customer/core/widgets/profile_avatar.dart';
import 'package:customer/features/auth/services/account_service.dart';
import 'package:customer/features/auth/state/auth_provider.dart';
import 'package:customer/features/auth/screens/change_password_screen.dart';
import 'package:customer/features/auth/screens/login_screen.dart';

/// The customer's profile: view/edit details, change password, delete account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _future;
  bool _wasLoggedIn = false;

  void _reload() => setState(() => _future = context.read<AccountService>().me());

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      _future = null; // reload on login / drop on logout
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: !loggedIn ? _signInPrompt(context) : _profileBody(context),
    );
  }

  Widget _signInPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Sign in to manage your account.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );

  Widget _profileBody(BuildContext context) {
    _future ??= context.read<AccountService>().me();
    return FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(snap.error.toString(), textAlign: TextAlign.center)));
          }
          final me = snap.data!;
          final profile = me['profile'] is Map ? me['profile'] as Map<String, dynamic> : const {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: _avatarHeader(me)),
              const SizedBox(height: 20),
              _row('Username', me['username']?.toString() ?? '—'),
              _row('Name', me['fullName']?.toString() ?? '—'),
              _row('Email', me['email']?.toString() ?? '—'),
              _row('Phone', me['phoneNumber']?.toString() ?? '—'),
              _row('Shipping address', (profile['shippingAddress'] as String?)?.isNotEmpty == true ? profile['shippingAddress'] as String : '—'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openEdit(me, profile),
                icon: const Icon(Icons.edit),
                label: const Text('Edit profile'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openChangePassword,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Change password'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete my account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      );
  }

  // big avatar with a camera badge to change the photo
  Widget _avatarHeader(Map<String, dynamic> me) {
    final url = (me['avatarUrl'] as String?)?.isNotEmpty == true ? me['avatarUrl'] as String : null;
    final name = me['fullName']?.toString() ?? '';
    return Stack(
      children: [
        ProfileAvatar(name: name, url: url, size: 96),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _changeAvatar(hasPhoto: url != null),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changeAvatar({required bool hasPhoto}) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    try {
      if (action == 'remove') {
        await context.read<AccountService>().removeAvatar();
      } else {
        final picked = await ImagePicker().pickImage(
          source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 800,
          imageQuality: 85,
        );
        if (picked == null) return;
        await context.read<AccountService>().uploadAvatar(File(picked.path));
      }
      if (mounted) _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Future<void> _openEdit(Map<String, dynamic> me, Map profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        fullName: me['fullName']?.toString() ?? '',
        username: me['username']?.toString() ?? '',
        phone: me['phoneNumber']?.toString() ?? '',
        address: (profile['shippingAddress'] as String?) ?? '',
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _openChangePassword() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This closes your account and signs you out. Your past orders are kept for records.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AccountService>().deleteAccount();
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

/// Shared field used by the profile sheets.
Widget _profileField(TextEditingController c, String label,
        {bool obscure = false, int maxLines = 1, String? errorText, VoidCallback? onChanged}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        onChanged: (errorText == null || onChanged == null) ? null : (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
      ),
    );

/// Edit-profile sheet — owns its controllers (disposed in dispose) and does its
/// own save, popping `true` on success so the caller can refresh.
class _EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String username;
  final String phone;
  final String address;
  const _EditProfileSheet({required this.fullName, required this.username, required this.phone, required this.address});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.fullName);
  late final TextEditingController _username = TextEditingController(text: widget.username);
  late final TextEditingController _phone = TextEditingController(text: widget.phone);
  late final TextEditingController _address = TextEditingController(text: widget.address);
  bool _saving = false;
  // per-field inline errors
  String? _nameError;
  String? _usernameError;
  String? _phoneError;

  @override
  void dispose() {
    for (final c in [_name, _username, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _nameError = _name.text.trim().isEmpty ? 'Full name is required.' : null;
      _usernameError = _username.text.trim().isEmpty ? 'Username is required.' : null;
    });
    if (_nameError != null || _usernameError != null) {
      setState(() => _saving = false);
      return;
    }
    try {
      await context.read<AccountService>().updateProfile(
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            username: _username.text.trim(),
            shippingAddress: _address.text.trim(),
          );
      await context.read<AuthProvider>().applyProfile(fullName: _name.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // route the server error to the most likely field, else under the username
      final msg = e.toString();
      final lower = msg.toLowerCase();
      if (mounted) {
        setState(() {
          _saving = false;
          if (lower.contains('phone')) {
            _phoneError = msg;
          } else if (lower.contains('name')) {
            _nameError = msg;
          } else {
            _usernameError = msg;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _profileField(_name, 'Full name',
              errorText: _nameError, onChanged: () => setState(() => _nameError = null)),
          _profileField(_username, 'Username',
              errorText: _usernameError, onChanged: () => setState(() => _usernameError = null)),
          _profileField(_phone, 'Phone number',
              errorText: _phoneError, onChanged: () => setState(() => _phoneError = null)),
          _profileField(_address, 'Shipping address', maxLines: 2),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
