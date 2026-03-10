import 'package:flutter/material.dart';
import 'package:pixpie/others/kyc_screen.dart';
import 'package:pixpie/screens/admin_login.dart';
import 'package:pixpie/screens/aoi_management.dart';
import 'package:provider/provider.dart';

import '../dashboard/admin_dashboard/dashboard.dart';
import '../provider/api_provider.dart';

class AdminSignup extends StatefulWidget {
  const AdminSignup({super.key});

  @override
  State<AdminSignup> createState() => _AdminSignupState();
}

class _AdminSignupState extends State<AdminSignup> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
 // final roleController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  final nameFocus = FocusNode();
  //final roleFocus = FocusNode();


  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
   // roleController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    nameFocus.dispose();
   // roleFocus.dispose();
    super.dispose();
  }
  bool _validateInputs() {
    if (emailController.text.isEmpty) {
      FocusScope.of(context).requestFocus(emailFocus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email cannot be empty")),
      );
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(emailController.text)) {
      FocusScope.of(context).requestFocus(emailFocus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return false;
    }
    if (passwordController.text.isEmpty) {
      FocusScope.of(context).requestFocus(passwordFocus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password cannot be empty")),
      );
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      FocusScope.of(context).requestFocus(confirmPasswordFocus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return false;
    }
    if (nameController.text.isEmpty) {
      FocusScope.of(context).requestFocus(nameFocus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return false;
    }
    // if (roleController.text.isEmpty) {
    //   FocusScope.of(context).requestFocus(roleFocus);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Role cannot be empty")),
    //   );
    //   return false;
    // }

    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (context, apiProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "SignUp Screen",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.brown,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
            children: [
            const SizedBox(height: 40),
              _label(text: "Name"),
              _textField2(
                controller: nameController,
                hint: "Enter full name",
                focusNode: nameFocus,
              ),

              const SizedBox(height: 20),

              _label(text: "Email"),
              _textField(
                controller: emailController,
                hint: "admin@pixpe.com",
                icon: Icons.email_outlined,
                focusNode: emailFocus,
              ),

              const SizedBox(height: 20),

              _label(text: "Password"),
              _textField(
                controller: passwordController,
                hint: "Enter password",
                icon: Icons.remove_red_eye,
                isPassword: true,
                isVisible: _passwordVisible,             // <-- use state here
                onToggle: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;  // <-- toggle
                  });
                },
                focusNode: passwordFocus,
              ),
              const SizedBox(height: 20),


              _label(text: "Confirm Password"),
              _textField(
                controller: confirmPasswordController,
                hint: "Confirm password",
                icon: Icons.remove_red_eye,
                isPassword: true,
                isVisible: _confirmPasswordVisible,         // <-- state
                onToggle: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible; // toggle
                  });
                },
                focusNode: confirmPasswordFocus,
              ),

              // const SizedBox(height: 20),
              //
              //
              //
              // _label(text: "Role"),
              // _textField2(
              //   controller: roleController,
              //   hint: "Enter role",
              //   focusNode: roleFocus,
              // ),

              const SizedBox(height: 40),

              SizedBox(
                width: _responsiveWidth(context),
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  onPressed: apiProvider.isLoading
                      ? null
                      : () async {
                    // ✅ Validate inputs
                    if (!_validateInputs()) return;

                    await apiProvider.adminSignUp(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      name: nameController.text.trim(),
                   //   role: roleController.text.trim(),
                    );

                    if (apiProvider.data != null &&
                        apiProvider.error == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KycScreen(),
                        ),
                      );
                    }
                  },
                  child: apiProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (apiProvider.error != null)
            Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
        apiProvider.error!,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
        ),
        ),


        TextButton(
        onPressed: () {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLogin()),
        );
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Do you Have an Account ?"),
              const Text("Login "),
            ],
          ),
        ),
        ),
        ],
        ),
            ),
          ),
        );
      },
    );
  }
  Widget _label({
    required String text,
  }) {
    return Center(
      child: Container(
        width: _responsiveWidth(context),
        margin: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,fontFamily: "poppins"
          ),
        ),
      ),
    );
  }

  // Modified textField to accept focusNode
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    FocusNode? focusNode,
  }) {
    return Center(
      child: SizedBox(
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
            hintStyle: const TextStyle(color: Color(0xff707C90), fontSize: 12, fontFamily: "poppins"),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 18),
              onPressed: onToggle,
            )
                : Icon(icon, color: Colors.grey, size: 18),
          ),
        ),
      ),
    );
  }



  double _responsiveWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      return 450; // tablet
    } else if (screenWidth > 400) {
      return screenWidth * 0.85; // large phones
    } else {
      return screenWidth * 0.92; // small phones
    }
  }
  Widget _textField2({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    FocusNode? focusNode,
  }) {
    return Center(
      child: SizedBox(
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
            hintStyle: const TextStyle(color: Color(0xff707C90), fontSize: 12, fontFamily: "poppins"),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
          ),
        ),
      ),
    );
  }

}
