import 'package:flutter/material.dart';
import 'package:pixpie/others/aoi_detail_screen.dart';
import 'package:provider/provider.dart';
import '../provider/api_provider.dart';

class AOIScreen extends StatefulWidget {
  const AOIScreen({super.key});

  @override
  State<AOIScreen> createState() => _AOIScreenState();
}

class _AOIScreenState extends State<AOIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().getAoi();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
      case 'inprogress':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high priority':
      case 'high':
        return Colors.red;
      case 'medium priority':
      case 'medium':
        return Colors.orange;
      case 'low priority':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in progress':
      case 'inprogress':
        return Icons.timelapse;
      case 'submitted':
        return Icons.send_outlined;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high priority':
      case 'high':
        return Icons.priority_high;
      case 'medium priority':
      case 'medium':
        return Icons.flag_outlined;
      case 'low priority':
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("AOIs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<ApiProvider>(
        builder: (context, apiProvider, child) {
          if (apiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (apiProvider.error != null) {
            return Center(child: Text(apiProvider.error!));
          }

          final aoiList = apiProvider.data ?? [];

          if (aoiList.isEmpty) {
            return const Center(
              child: Text(
                "No AOIs Assigned",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => apiProvider.getAoi(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: aoiList.length,
              itemBuilder: (context, index) {
                final raw = aoiList[index];
                if (raw == null || raw is! Map<String, dynamic>) {
                  return const SizedBox();
                }

                final Map<String, dynamic> aoi = raw;
                final aoiName = aoi["aoi_name"]?.toString() ?? "Unnamed AOI";
                final status = aoi["status"]?.toString() ?? "unknown";
                final priority = aoi["priority"]?.toString() ?? "MEDIUM";
                final List<Map<String, dynamic>> pois =
                    (aoi["pois"] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                        [];
                final List<Map<String, dynamic>> boundaryCoordinates =
                    (aoi["boundary_coordinates"] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                        [];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AoiDetailScreen(
                          aoi: {
                            ...aoi,
                            "boundary_coordinates": boundaryCoordinates,
                          },
                          pois: pois,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// 🔹 Status Accent Bar
                        Container(
                          width: 6,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// AOI Title
                                Text(
                                  aoiName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                /// Summary row
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.place_outlined,
                                            size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${pois.length} POIs",
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.timeline_outlined,
                                            size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${boundaryCoordinates.length} Boundary Points",
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                /// Status & Priority Chips
                                Row(
                                  children: [
                                    Chip(
                                      backgroundColor:
                                      _getStatusColor(status).withOpacity(0.1),
                                      avatar: Icon(
                                        _getStatusIcon(status),
                                        size: 18,
                                        color: _getStatusColor(status),
                                      ),
                                      label: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                    const SizedBox(width: 12),
                                    Chip(
                                      backgroundColor:
                                      _getPriorityColor(priority).withOpacity(0.1),
                                      avatar: Icon(
                                        _getPriorityIcon(priority),
                                        size: 18,
                                        color: _getPriorityColor(priority),
                                      ),
                                      label: Text(
                                        priority.toUpperCase(),
                                        style: TextStyle(
                                          color: _getPriorityColor(priority),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}