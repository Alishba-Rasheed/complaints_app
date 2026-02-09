import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';
import 'register_screen.dart';
import 'user/user_home_screen.dart'; // Will create
import 'admin/admin_home_screen.dart'; // Will create
import 'super/super_dashboard.dart'; // Will create

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';

  void _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    
    final success = await auth.login(
      _usernameController.text,
      _passwordController.text,
      _selectedRole,
    );

    if (success && mounted) {
      debugPrint("LOGIN SUCCESS: Role=${auth.role}, Authenticated=${auth.isAuthenticated}");
      
      // Explicit navigation as backup to reactive AuthWrapper
      Widget nextScreen;
      final role = auth.role?.trim().toLowerCase();
      if (role == 'user') nextScreen = const UserHomeScreen();
      else if (role == 'admin') nextScreen = const AdminHomeScreen();
      else if (role == 'super' || role == 'super admin') nextScreen = const SuperDashboard();
      else nextScreen = const UserHomeScreen(); // Default fallback

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => nextScreen),
        (route) => false,
      );
    } else if (mounted) {
      String message = l10n?.loginFailed ?? 'Login failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF1976D2).withOpacity(0.05),
              const Color(0xFF64B5F6).withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Switcher at top
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    LanguageDropdown(),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.security_rounded, size: 40, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n?.welcomeBack ?? 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 36, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF0D47A1),
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  l10n?.signInToPortal ?? 'Sign in to your portal',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(
                  controller: _usernameController,
                  label: l10n?.username ?? 'Username',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _passwordController,
                  label: l10n?.password ?? 'Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n?.selectPortal ?? 'SELECT PORTAL',
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.blueGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _expandedRoleChip(l10n?.user ?? 'User', 'user', Icons.person_rounded),
                    const SizedBox(width: 12),
                    _expandedRoleChip(l10n?.admin ?? 'Admin', 'admin', Icons.admin_panel_settings_rounded),
                    const SizedBox(width: 12),
                    _expandedRoleChip(l10n?.superAdmin ?? 'Super', 'super', Icons.bolt_rounded),
                  ],
                ),
                const SizedBox(height: 48),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFF1976D2).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : Text(
                                l10n?.continueBtn ?? 'CONTINUE', 
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.blueGrey.shade600),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                        children: [
                          TextSpan(text: "${l10n?.dontHaveAccount ?? "Don't have an account?"} "),
                          TextSpan(
                            text: l10n?.registerNow ?? 'Register Now', 
                            style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _expandedRoleChip(String label, String value, IconData icon) {
    bool isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF1976D2) : Colors.blueGrey.shade100,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : Colors.blueGrey.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}