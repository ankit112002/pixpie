import 'package:flutter/material.dart';
import 'package:pixpie/others/aoi_screen.dart';
import 'package:provider/provider.dart';
import '../../others/app_drawer.dart';
import '../../provider/api_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiProvider>(context, listen: false).getAoi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 Change this to your desired color
        ),
      ),
      drawer: const AppDrawer(), // <-- Use your real drawer here

      body: Consumer<ApiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final aois = (provider.data as List<dynamic>?) ?? [];

          final activeCount = aois.length;
          final photosToday = 0;
          final completedCount = 1;
          final todaysEarnings = 0;

          String surveyorName = "Surveyor";

          if (aois.isNotEmpty &&
              aois[0]["assigned_to_surveyor"] != null &&
              aois[0]["assigned_to_surveyor"]["name"] != null) {
            surveyorName =
                aois[0]["assigned_to_surveyor"]["name"].toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, $surveyorName",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's your Pixpe progress for today",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // ----------------- Summary Cards -----------------
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      children: [
                        _buildProfessionalSummaryCard(
                          "Active AOIs",
                          "$activeCount",
                          Icons.location_on,
                          Colors.deepPurple,
                          screenWidth,
                        ),
                        _buildProfessionalSummaryCard(
                          "Photos Today",
                          "$photosToday",
                          Icons.camera_alt,
                          Colors.teal,
                          screenWidth,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildProfessionalSummaryCard(
                          "Completed",
                          "$completedCount",
                          Icons.check_circle,
                          Colors.orange,
                          screenWidth,
                        ),
                        _buildProfessionalSummaryCard(
                          "PixPoint",
                          "₹$todaysEarnings",
                          Icons.currency_rupee,
                          Colors.pink,
                          screenWidth,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ----------------- Quick Action Cards -----------------
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AOIScreen(),
                              ),
                            );
                          },
                          child: _buildProfessionalActionCard(
                            "View AOIs",
                            Icons.map,
                            screenWidth,
                          ),
                        ),
                        _buildProfessionalActionCard(
                          "Quick Capture",
                          Icons.camera_alt,
                          screenWidth,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildProfessionalActionCard(
                          "PixPoint",
                          Icons.account_balance_wallet,
                          screenWidth,
                        ),
                        _buildProfessionalActionCard(
                          "Report",
                          Icons.report_problem_outlined,
                          screenWidth,
                        ),
                      ],
                    ),
                  ],
                ),
                // ----------------- AOI Carousel -----------------
                const SizedBox(height: 24),
                const Text(
                  "Your AOIs",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 180, // height of the cards
                  child: aois.isEmpty
                      ? const Center(child: Text("No AOIs available"))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: aois.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final aoi = aois[index];
                            return SizedBox(
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.6, // each card width
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black26,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aoi['aoi_name'] ?? 'Unnamed AOI',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Code: ${aoi['aoi_code']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${aoi['city'] ?? '-'}, ${aoi['state'] ?? '-'}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------- Professional Summary Card -----------------
  Widget _buildProfessionalSummaryCard(
    String title,
    String count,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return SizedBox(
      width: screenWidth * 0.45,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: color.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- Professional Action Card -----------------
  Widget _buildProfessionalActionCard(
    String title,
    IconData icon,
    double screenWidth,
  ) {
    return SizedBox(
      width: screenWidth * 0.45,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: InkWell(
          onTap: () {
            // Handle action
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36, color: Colors.deepPurple),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------- Professional AOI Card -----------------
  Widget _buildProfessionalAoiCard(dynamic aoi, double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.45,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aoi['aoi_name'] ?? 'Unnamed AOI',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "Code: ${aoi['aoi_code']}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                "${aoi['city'] ?? '-'}, ${aoi['state'] ?? '-'}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
