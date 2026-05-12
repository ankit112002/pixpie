import 'package:flutter/material.dart';
import 'package:pixpie/others/kyc_screen.dart';
import 'package:pixpie/screens/admin_login.dart';
import 'package:provider/provider.dart';

import '../provider/api_provider.dart';

class AdminSignup extends StatefulWidget {
  const AdminSignup({super.key});

  @override
  State<AdminSignup> createState() => _AdminSignupState();
}

class _AdminSignupState extends State<AdminSignup>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  final nameFocus = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    nameFocus.dispose();

    super.dispose();
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showMessage("Name cannot be empty");
      FocusScope.of(context).requestFocus(nameFocus);
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showMessage("Email cannot be empty");
      FocusScope.of(context).requestFocus(emailFocus);
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}')
        .hasMatch(emailController.text.trim())) {
      _showMessage("Enter valid email");
      FocusScope.of(context).requestFocus(emailFocus);
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      _showMessage("Password must be at least 6 characters");
      FocusScope.of(context).requestFocus(passwordFocus);
      return false;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showMessage("Passwords do not match");
      FocusScope.of(context).requestFocus(confirmPasswordFocus);
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
                /// TOP BACKGROUND
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

                /// DECORATIVE CIRCLES
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

                /// CONTENT
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      /// APP LOGO
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
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Manage your Pixpe dashboard professionally",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 36),

                      /// CARD
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
                            _buildTextField(
                              controller: nameController,
                              hint: "Full Name",
                              icon: Icons.person_outline_rounded,
                              focusNode: nameFocus,
                            ),

                            _buildTextField(
                              controller: emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                              focusNode: emailFocus,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            _buildTextField(
                              controller: passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline_rounded,
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

                            _buildTextField(
                              controller:
                              confirmPasswordController,
                              hint: "Confirm Password",
                              icon: Icons.lock_outline_rounded,
                              focusNode: confirmPasswordFocus,
                              isPassword: true,
                              isVisible:
                              _confirmPasswordVisible,
                              onToggle: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                                });
                              },
                            ),

                            const SizedBox(height: 10),

                            /// BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: apiProvider.isLoading
                                    ? null
                                    : () async {
                                  if (!_validateInputs()) {
                                    return;
                                  }

                                  await apiProvider.adminSignUp(
                                    email: emailController
                                        .text
                                        .trim(),
                                    password:
                                    passwordController
                                        .text
                                        .trim(),
                                    name: nameController
                                        .text
                                        .trim(),
                                  );

                                  if (apiProvider.data !=
                                      null &&
                                      apiProvider.error ==
                                          null) {
                                    if (!mounted) return;

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const KycScreen(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                  const Color(0xFF7C3AED),
                                  shape: RoundedRectangleBorder(
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
                                  "Create Account",
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
                                const EdgeInsets.only(top: 16),
                                child: Text(
                                  apiProvider.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const AdminLogin(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color(0xFF7C3AED),
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