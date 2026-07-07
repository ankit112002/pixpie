import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/api_provider.dart';
import 'aoi_detail_screen.dart';

/// Same palette used across the app (dashboard, drawer, profile, AOIs, etc.)
/// so every screen reads as one cohesive, professional design system.
class _Palette {
  static const primary = Color(0xFF4B2FBF);
  static const primaryDark = Color(0xFF37217F);
  static const background = Color(0xFFF5F6FA);
  static const cardBorder = Color(0xFFEDEDF3);
  static const textPrimary = Color(0xFF1D1B2E);
  static const textSecondary = Color(0xFF6E6B80);

  static const success = Color(0xFF1FA971);
  static const warning = Color(0xFFE08A2E);
  static const danger = Color(0xFFD7263D);
  static const info = Color(0xFF2E86DE);
  static const neutral = Color(0xFF8E8E9B);
}

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
        return _Palette.success;
      case 'in progress':
      case 'inprogress':
        return _Palette.warning;
      case 'submitted':
        return _Palette.info;
      default:
        return _Palette.neutral;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high priority':
      case 'high':
        return _Palette.danger;
      case 'medium priority':
      case 'medium':
        return _Palette.warning;
      case 'low priority':
      case 'low':
        return _Palette.success;
      default:
        return _Palette.neutral;
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
      backgroundColor: _Palette.background,
      appBar: AppBar(
        title: const Text(
          "AOIs",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
        ),
        backgroundColor: _Palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_Palette.primary, _Palette.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<ApiProvider>(
        builder: (context, apiProvider, child) {
          if (apiProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _Palette.primary),
            );
          }

          if (apiProvider.error != null) {
            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () async {
                await apiProvider.getAoi();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _Palette.danger.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline_rounded,
                                size: 60, color: _Palette.danger),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Something went wrong",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            apiProvider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 160,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => apiProvider.getAoi(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _Palette.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Retry",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Or pull down to refresh",
                            style:
                            TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final List<dynamic> aoiList = apiProvider.data ?? [];

          if (aoiList.isEmpty) {
            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () => apiProvider.getAoi(),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _Palette.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.map_outlined,
                                size: 56, color: _Palette.primary),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "No AOIs Assigned",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Pull down to refresh",
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: _Palette.primary,
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

                final String aoiName = aoi["aoi_name"]?.toString() ?? "Unnamed AOI";
                final String status = aoi["status"]?.toString() ?? "UNKNOWN";
                final String priority = aoi["priority"]?.toString() ?? "MEDIUM";

                /// API has boundary_geojson
                final Map<String, dynamic>? boundaryGeoJson =
                aoi["boundary_geojson"] as Map<String, dynamic>?;

                final List coordinates =
                    boundaryGeoJson?["coordinates"] ?? [];

                final int boundaryPoints =
                coordinates.isNotEmpty ? coordinates[0].length : 0;

                /// POIs (optional)
                final List<Map<String, dynamic>> pois =
                    (aoi["pois"] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                        [];

                final statusColor = _getStatusColor(status);
                final priorityColor = _getPriorityColor(priority);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _Palette.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      splashColor: _Palette.primary.withOpacity(0.06),
                      highlightColor: _Palette.primary.withOpacity(0.03),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AoiDetailScreen(
                              aoi: aoi,
                              pois: pois,
                            ),
                          ),
                        );
                      },
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            /// STATUS BAR
                            Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    /// AOI NAME
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            aoiName,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.1,
                                              color: _Palette.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            color: Colors.grey.shade400),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    /// SUMMARY
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined,
                                            size: 16,
                                            color: _Palette.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${pois.length} POIs",
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              color: _Palette.textSecondary),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.timeline_outlined,
                                            size: 16,
                                            color: _Palette.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "$boundaryPoints Boundary Points",
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                color: _Palette.textSecondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    /// STATUS + PRIORITY
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [

                                        /// STATUS
                                        _buildTag(
                                          icon: _getStatusIcon(status),
                                          color: statusColor,
                                          label: status.toUpperCase(),
                                        ),

                                        /// PRIORITY
                                        _buildTag(
                                          icon: _getPriorityIcon(priority),
                                          color: priorityColor,
                                          label: priority.toUpperCase(),
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

  Widget _buildTag({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}