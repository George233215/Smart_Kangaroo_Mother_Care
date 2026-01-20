import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditDialog extends StatefulWidget {
  final User user;

  const ProfileEditDialog({super.key, required this.user});

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile form controllers
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Password form controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _displayNameController.text = widget.user.displayName ?? '';
    _emailController.text = widget.user.email ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.pink[400]!, Colors.purple[300]!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.pink[400],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.pink[400],
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.person_outline),
                    text: 'Profile Info',
                  ),
                  Tab(
                    icon: Icon(Icons.lock_outline),
                    text: 'Password',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildPasswordTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[400]!, Colors.purple[300]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_displayNameController.text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.pink[400], size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Display Name Field
          _buildLabel('Display Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _displayNameController,
            hintText: 'Enter your name',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),

          // Email Field (Read-only)
          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hintText: 'Your email',
            prefixIcon: Icons.email_outlined,
            readOnly: true,
            suffixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Email cannot be changed for security reasons',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For security, you need to enter your current password to change it',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Current Password
          _buildLabel('Current Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _currentPasswordController,
            hintText: 'Enter current password',
            obscureText: _obscureCurrentPassword,
            onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
          ),
          const SizedBox(height: 20),

          // New Password
          _buildLabel('New Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _newPasswordController,
            hintText: 'Enter new password',
            obscureText: _obscureNewPassword,
            onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
          const SizedBox(height: 20),

          // Confirm Password
          _buildLabel('Confirm New Password'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Re-enter new password',
            obscureText: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          const SizedBox(height: 32),

          // Update Password Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey[400], size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    final strength = _calculatePasswordStrength(password);

    Color strengthColor;
    String strengthText;

    if (strength < 0.3) {
      strengthColor = Colors.red;
      strengthText = 'Weak';
    } else if (strength < 0.6) {
      strengthColor = Colors.orange;
      strengthText = 'Fair';
    } else if (strength < 0.8) {
      strengthColor = Colors.blue;
      strengthText = 'Good';
    } else {
      strengthColor = Colors.green;
      strengthText = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: password.isEmpty ? 0 : strength,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (password.isNotEmpty)
              Text(
                strengthText,
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Password must be at least 8 characters with uppercase, lowercase, and numbers',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    // Length
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;

    // Uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;

    // Lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;

    // Numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;

    // Special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    return strength.clamp(0.0, 1.0);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      _showErrorSnackBar('Please enter a display name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.user.updateDisplayName(displayName);
      await widget.user.reload();

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Profile updated successfully!');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar('Please fill in all password fields');
      return;
    }

    if (newPassword.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    if (currentPassword == newPassword) {
      _showErrorSnackBar('New password must be different from current password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: currentPassword,
      );
      await widget.user.reauthenticateWithCredential(credential);

      // Update password
      await widget.user.updatePassword(newPassword);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Password updated successfully!');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'wrong-password') {
          _showErrorSnackBar('Current password is incorrect');
        } else if (e.code == 'weak-password') {
          _showErrorSnackBar('Password is too weak');
        } else {
          _showErrorSnackBar(e.message ?? 'Failed to update password');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}