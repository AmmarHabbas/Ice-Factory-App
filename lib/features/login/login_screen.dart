import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username.isEmpty && password.isEmpty
                      ? 'Username and password fields are empty.'
                      : username.isEmpty
                      ? 'Username field is empty.'
                      : 'Password field is empty.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (username != 'admin' || password != 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Login credentials are wrong.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isLoggingIn = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoggingIn = false);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return EnglishLocalizationsOverride(
      child: Scaffold(
        body: Stack(
          children: [
            // Ambient blue/ice glow.
            Positioned(
              top: -90,
              right: -70,
              child: _blurCircle(
                size: 290,
                color: const Color(0xFFA5D8FF).withValues(alpha: 0.40),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * .40,
              left: -120,
              child: _blurCircle(
                size: 320,
                color: const Color(0xFFD5E3FF).withValues(alpha: 0.32),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildLoginCard(),
                        const SizedBox(height: 18),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Replace this URL with your local company logo asset if available.
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001E40).withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida/AEtjO1Um0bO-DkmCcCqYS0M4wuSiLiTrLxgcZ-NxbluRLtX5oRqL3Octmzg3HmHgsulVjktsqKCBqi67UF23gsYxZdd9do0XIy63IgH1T49kHBX5w4NVQcQBe3JsbHhwjjXpypXkVjPiUxzr-s7ANz6RjUXnggUhEgGP5MoamHhRO7b9cuD2G187_mB6NS5mFSyYNdaP22r9BvtWxwg6E36atD2JA-WJ1dR3BLf7RxvMOeaePw5IhshREf09zEZlY07OX9Ue0aVg3dgf',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.ac_unit_rounded,
                size: 48,
                color: Color(0xFF003366),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Fawares Al Sham Co.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF001E40),
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w600,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ice Distribution & Factory Operations',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF43474F), fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001E40).withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Username'),
          const SizedBox(height: 6),
          _buildUsernameField(),
          const SizedBox(height: 16),

          _buildFieldLabel('Password'),
          const SizedBox(height: 6),
          _buildPasswordField(),
          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
                activeColor: const Color(0xFF001E40),
                visualDensity: VisualDensity.compact,
              ),
              const Expanded(
                child: Text(
                  'Remember me',
                  style: TextStyle(color: Color(0xFF43474F), fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E6385),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isLoggingIn ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF001E40),
                disabledBackgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoggingIn
                    ? const Row(
                        key: ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connecting to Logistics Engine...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Log In',
                        key: ValueKey('login'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(
        hint: 'Enter username',
        icon: Icons.badge_outlined,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _login(),
      decoration:
          _inputDecoration(
            hint: '••••••••',
            icon: Icons.lock_open_outlined,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF737780),
                size: 20,
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF737780), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF737780), size: 20),
      filled: true,
      fillColor: const Color(0xFFEFF4FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF001E40), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF43474F),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF2E6385)),
        const SizedBox(width: 6),
        Text(
          'Secure Factory Operations',
          style: TextStyle(
            color: const Color(0xFF43474F).withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _blurCircle({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
