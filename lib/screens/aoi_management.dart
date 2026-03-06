import 'package:flutter/material.dart';
import 'package:pixpie/screens/user_management_mobile.dart';

class AOIManagementMobile extends StatelessWidget {
  const AOIManagementMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      /// App Bar
      appBar: AppBar(
        title: const Text("AOI Management"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      /// Drawer (Sidebar for mobile)
      drawer: const AOIDrawer(),

      /// Body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create and manage survey areas",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
        
              /// AOI List
              Expanded(
                child: ListView(
                  children: const [
                    AOIMobileCard(
                      title: "DEMO-AOI-10",
                      status: "IN_PROGRESS",
                      code: "AOI-2026-1008",
                      assignedTo: "vivek panwar",
                    ),
                    AOIMobileCard(
                      title: "Connaught Place Block edit",
                      status: "CLOSED",
                      code: "AOI-2026-1001",
                      assignedTo: "Field Surveyor",
                    ),
                    AOIMobileCard(
                      title: "AOI-VK",
                      status: "SUBMITTED",
                      code: "AOI-2026-1006",
                      assignedTo: "vivek panwar",
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),

      /// Floating Create Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserManagementMobile(),));
        },
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Create AOI"),
      ),
    );
  }
}
class AOIDrawer extends StatelessWidget {
  const AOIDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: const [
          SizedBox(height: 20,),
          Padding(
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
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.dashboard), title: Text("Dashboard")),
          ListTile(
              leading: Icon(Icons.location_on),
              title: Text("AOI Management")),
          ListTile(
              leading: Icon(Icons.place), title: Text("POI Management")),
          ListTile(
              leading: Icon(Icons.verified), title: Text("POI Approval")),
          ListTile(
              leading: Icon(Icons.assignment), title: Text("KYC Requests")),
          ListTile(
              leading: Icon(Icons.description), title: Text("Forms Management")),
          ListTile(leading: Icon(Icons.analytics), title: Text("Analytics")),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}class AOIMobileCard extends StatelessWidget {
  final String title;
  final String status;
  final String code;
  final String assignedTo;

  const AOIMobileCard({
    super.key,
    required this.title,
    required this.status,
    required this.code,
    required this.assignedTo,
  });

  Color getStatusColor() {
    switch (status) {
      case "IN_PROGRESS":
        return Colors.orange;
      case "CLOSED":
        return Colors.grey;
      case "SUBMITTED":
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

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
          /// Title
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          /// Status + Code
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(code, style: const TextStyle(color: Colors.grey)),
              Text("• $assignedTo",
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 12),

          /// Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text("Assign"),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_vert),
            ],
          )
        ],
      ),
    );
  }
}