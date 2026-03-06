import 'package:flutter/material.dart';

class UserManagementMobile extends StatelessWidget {
  const UserManagementMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        title: Row(
          children: [
            const Text("User Management"),
            IconButton(onPressed: (){
              Navigator.pop(context);
            }, icon: Text("Exit"))
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      drawer: const UserDrawer(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AddUserDialog(),
          );
        },
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add User"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Manage system users and roles",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            /// Search + Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text("All Roles"),
                      Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),

            /// User List
            Expanded(
              child: ListView(
                children: const [
                  UserMobileCard(
                    name: "test",
                    email: "vivekpanwar390@gmail.com",
                    role: "Surveyor",
                    status: "active",
                    activity: "0 surveys",
                  ),
                  UserMobileCard(
                    name: "Super Admin",
                    email: "admin@pixpe.com",
                    role: "Admin",
                    status: "active",
                    activity: "",
                  ),
                  UserMobileCard(
                    name: "vivek panwar",
                    email: "vivek@gmail.com",
                    role: "Surveyor",
                    status: "active",
                    activity: "0 surveys",
                  ),
                  UserMobileCard(
                    name: "Manager",
                    email: "manager@gmail.com",
                    role: "Manager",
                    status: "active",
                    activity: "0 managed",
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
class UserMobileCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String status;
  final String activity;

  const UserMobileCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          /// Email
          Text(
            email,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _chip(role, Colors.grey.shade300, Colors.black),
              _chip(status, Colors.black, Colors.white),
              if (activity.isNotEmpty)
                Text(activity, style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.power_settings_new,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const SizedBox(height: 20,),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Pixpe",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ListTile(leading: Icon(Icons.dashboard), title: Text("Dashboard")),
          const ListTile(
              leading: Icon(Icons.people),
              title: Text("User Management")),
          const ListTile(
              leading: Icon(Icons.settings),
              title: Text("System Settings")),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
         
        ],
      ),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  String selectedRole = "Editor";

  final List<String> roles = ["Admin", "Manager", "Surveyor", "Editor"];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add New User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                "Create a new account with specific role access.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              /// Full Name
              const Text("Full Name",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _inputField(
                controller: fullNameController,
                hint: "John Doe",
              ),

              const SizedBox(height: 16),

              /// Email
              const Text("Email Address",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _inputField(
                controller: emailController,
                hint: "john@example.com",
              ),

              const SizedBox(height: 16),

              /// Password
              const Text("Password",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  filled: true,
                  fillColor: const Color(0xffF5F6FA),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Role Dropdown
              const Text("Role",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: roles
                        .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              /// Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle create account
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Create Account"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xffF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}