import 'package:flutter/material.dart';
import 'package:pixpie/dashboard/admin_dashboard/dashboard.dart';
import 'package:pixpie/screens/admin_signup.dart';
import 'package:provider/provider.dart';

import '../provider/api_provider.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _passwordVisible = false;

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  /// VALIDATION
  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage("Email is required");
      FocusScope.of(context).requestFocus(emailFocus);
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}')
        .hasMatch(email)) {
      _showMessage("Enter valid email");
      FocusScope.of(context).requestFocus(emailFocus);
      return false;
    }

    if (password.isEmpty) {
      _showMessage("Password is required");
      FocusScope.of(context).requestFocus(passwordFocus);
      return false;
    }

    return true;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// LOGIN
  Future<void> _handleLogin(ApiProvider apiProvider) async {
    if (!_validateInputs()) return;

    await apiProvider.loginAdmin(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (apiProvider.error != null) {
      _showMessage(apiProvider.error!);
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: isPassword && !isVisible,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF7C3AED),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
            onPressed: onToggle,
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.grey.shade600,
            ),
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<ApiProvider>(
      builder: (context, apiProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          body: SafeArea(
            child: Stack(
              children: [
                /// TOP PURPLE BACKGROUND
                Container(
                  height: size.height * 0.38,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF5B21B6),
                        Color(0xFF4C1D95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                /// DECORATION
                Positioned(
                  top: -40,
                  right: -20,
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),

                Positioned(
                  top: 100,
                  left: -30,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                /// MAIN CONTENT
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      /// LOGO
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 46,
                          color: Color(0xFF7C3AED),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Login to continue to Pixpe",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 36),

                      /// LOGIN CARD
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            /// EMAIL
                            _buildTextField(
                              controller: emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                              focusNode: emailFocus,
                              keyboardType:
                              TextInputType.emailAddress,
                            ),

                            /// PASSWORD
                            _buildTextField(
                              controller: passwordController,
                              hint: "Password",
                              icon:
                              Icons.lock_outline_rounded,
                              focusNode: passwordFocus,
                              isPassword: true,
                              isVisible: _passwordVisible,
                              onToggle: () {
                                setState(() {
                                  _passwordVisible =
                                  !_passwordVisible;
                                });
                              },
                            ),

                            const SizedBox(height: 8),

                            /// FORGOT PASSWORD
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed:
                                apiProvider.isLoading
                                    ? null
                                    : () => _handleLogin(
                                  apiProvider,
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                  const Color(
                                    0xFF7C3AED,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),
                                child: apiProvider.isLoading
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            if (apiProvider.error != null)
                              Padding(
                                padding:
                                const EdgeInsets.only(
                                  top: 16,
                                ),
                                child: Text(
                                  apiProvider.error!,
                                  textAlign:
                                  TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            /// SIGNUP
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color:
                                    Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator
                                        .pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const AdminSignup(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color:
                                      Color(0xFF7C3AED),
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
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
}