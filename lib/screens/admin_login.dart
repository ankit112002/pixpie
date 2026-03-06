import 'package:flutter/material.dart';
import 'package:pixpie/dashboard/admin_dashboard/dashboard.dart';
import 'package:pixpie/screens/admin_signup.dart';
import 'package:pixpie/screens/aoi_management.dart';
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

  // ✅ Focus nodes
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

  double _responsiveWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return 450;
    if (screenWidth > 400) return screenWidth * 0.85;
    return screenWidth * 0.92;
  }

  Widget _label({required String text}) {
    return Container(
      width: _responsiveWidth(context),
      margin: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 13, fontFamily: "poppins"),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    IconData? icon,
    FocusNode? focusNode,
  }) {
    return SizedBox(
      width: _responsiveWidth(context),
      height: 43,
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        focusNode: focusNode,
        maxLines: 1,
        style: const TextStyle(fontSize: 13, fontFamily: "poppins"),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          hintStyle: const TextStyle(
              color: Color(0xff707C90), fontSize: 12, fontFamily: "poppins"),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
                size: 18),
            onPressed: onToggle,
          )
              : icon != null
              ? Icon(icon, color: Colors.grey, size: 18)
              : null,
        ),
      ),
    );
  }

  /// ✅ Validate inputs and move focus
  bool _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      FocusScope.of(context).requestFocus(emailFocus);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Email is required")));
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(email)) {
      FocusScope.of(context).requestFocus(emailFocus);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter a valid email")));
      return false;
    }

    if (password.isEmpty) {
      FocusScope.of(context).requestFocus(passwordFocus);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Password is required")));
      return false;
    }

    return true;
  }

  void _handleLogin(ApiProvider apiProvider) async {
    if (!_validateInputs()) return; // ✅ Validate first

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    await apiProvider.loginAdmin(email: email, password: password);

    if (apiProvider.error == null && apiProvider.data != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else if (apiProvider.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiProvider.error!)));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (context, apiProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "SignIn Screen",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.brown,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child:  Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _label(text: "Email"),
                    _textField(
                        controller: emailController,
                        hint: "admin@pixpe.com",
                        icon: Icons.email_outlined,
                        focusNode: emailFocus),
                    const SizedBox(height: 20),
                    _label(text: "Password"),
                    _textField(
                      controller: passwordController,
                      hint: "Enter password",
                      isPassword: true,
                      isVisible: _passwordVisible,
                      onToggle: () {
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                      focusNode: passwordFocus,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: _responsiveWidth(context),
                      height: 45,
                      child:ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                        onPressed: apiProvider.isLoading
                            ? null
                            : () => _handleLogin(apiProvider),
                        child: apiProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Login",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminSignup()));
                        },
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("You Don't Have An Account ?"),
                               Text(" SignUp "),
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}