import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../others/aoi_screen.dart';
import '../../others/app_drawer.dart';
import '../../others/earning_screen.dart';
import '../../others/unassigned_aoi_screen.dart';
import '../../provider/aoi_provider.dart';
import '../../provider/api_provider.dart';

/// Centralized palette so the whole screen reads as one cohesive,
/// professional design instead of scattered ad-hoc colors.
class _Palette {
  static const primary = Color(0xFF4B2FBF); // deep purple
  static const primaryDark = Color(0xFF37217F);
  static const primaryLight = Color(0xFF7C5CFC);
  static const background = Color(0xFFF5F6FA);
  static const cardBorder = Color(0xFFEDEDF3);
  static const textPrimary = Color(0xFF1D1B2E);
  static const textSecondary = Color(0xFF6E6B80);

  static const success = Color(0xFF1FA971);
  static const info = Color(0xFF0EA5A5);
  static const warning = Color(0xFFE08A2E);
  static const accent = Color(0xFFDB2D69);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final apiProvider =
      Provider.of<ApiProvider>(context, listen: false);

      final aoiProvider =
      Provider.of<AoiProvider>(context, listen: false);

      await apiProvider.getAoi();

      // Fetch photos for all AOIs
      final aois =
      apiProvider.data is List ? apiProvider.data as List : [];

      int totalPhotos = 0;

      for (var aoi in aois) {
        final aoiId = aoi['id'].toString();

        await aoiProvider.fetchMyUploadedPhotos(aoiId);

        totalPhotos += aoiProvider.myPhotos.length;
      }

      // Store total dynamically
      aoiProvider.totalUploadedPhotos = totalPhotos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        backgroundColor: _Palette.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
      drawer: const AppDrawer(), // <-- Use your real drawer here

      body: Consumer2<ApiProvider, AoiProvider>(
        builder: (context, provider, aoiProvider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: _Palette.primary,
              ),
            );
          }

          if (provider.error != null) {
            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () async {
                await provider.getAoi();
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
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_off_rounded,
                                size: 60, color: Colors.redAccent),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Connection Error",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _Palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 170,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => provider.getAoi(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _Palette.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Try Again",
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

          final aois = provider.data is List ? provider.data as List : [];

          final activeCount = aois.length;
          final photosToday = aoiProvider.totalUploadedPhotos;
          final todaysEarnings = 0;

          /// Count completed AOIs dynamically
          final completedCount = aois
              .where((aoi) =>
          aoi != null &&
              aoi is Map<String, dynamic> &&
              (aoi["status"]?.toString().toUpperCase() == "COMPLETED"))
              .length;

          String surveyorName = "Surveyor";

          if (aois.isNotEmpty &&
              aois[0]["assigned_to_surveyor"] != null &&
              aois[0]["assigned_to_surveyor"]["name"] != null) {
            surveyorName =
                aois[0]["assigned_to_surveyor"]["name"].toString();
          }

          return RefreshIndicator(
            color: _Palette.primary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await provider.getAoi();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back, $surveyorName",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's your PixPe progress for today",
                    style: TextStyle(
                        fontSize: 14, color: _Palette.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // ----------------- Summary Cards -----------------
                  Row(
                    children: [
                      _buildProfessionalSummaryCard(
                        "Active AOIs",
                        "$activeCount",
                        Icons.location_on_rounded,
                        _Palette.primary,
                        screenWidth,
                      ),
                      const SizedBox(width: 12),
                      _buildProfessionalSummaryCard(
                        "Photos Today",
                        "$photosToday",
                        Icons.camera_alt_rounded,
                        _Palette.info,
                        screenWidth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildProfessionalSummaryCard(
                        "Completed",
                        "$completedCount",
                        Icons.check_circle_rounded,
                        _Palette.warning,
                        screenWidth,
                      ),
                      const SizedBox(width: 12),
                      _buildProfessionalSummaryCard(
                        "PixPoint",
                        "$todaysEarnings",
                        Icons.currency_rupee_rounded,
                        _Palette.accent,
                        screenWidth,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ----------------- Quick Action Cards -----------------
                  Row(
                    children: [
                      _buildProfessionalActionCard(
                        "View Assigned\nAOIs",
                        Icons.map_rounded,
                        screenWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AOIScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildProfessionalActionCard(
                        "View Unassigned\nAOIs",
                        Icons.map_outlined,
                        screenWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const UnassignedAoiScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildProfessionalActionCard(
                        "PixPoint",
                        Icons.account_balance_wallet_rounded,
                        screenWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EarningsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildProfessionalActionCard(
                        "Report",
                        Icons.report_problem_outlined,
                        screenWidth,
                      ),
                    ],
                  ),

                  // ----------------- AOI Carousel -----------------
                  const SizedBox(height: 28),
                  const Text(
                    "Your AOIs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 186, // height of the cards
                    child: aois.isEmpty
                        ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Palette.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          "No AOIs available",
                          style: TextStyle(
                              color: _Palette.textSecondary,
                              fontSize: 14),
                        ),
                      ),
                    )
                        : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: aois.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final aoi = aois[index];
                        final status = aoi is Map
                            ? (aoi['status']?.toString() ?? '')
                            : '';
                        return SizedBox(
                          width:
                          MediaQuery.of(context).size.width *
                              0.62, // each card width
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border:
                              Border.all(color: _Palette.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          aoi['aoi_name'] ?? 'Unnamed AOI',
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.bold,
                                            color: _Palette.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (status.isNotEmpty)
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                          decoration: BoxDecoration(
                                            color: status.toUpperCase() ==
                                                "COMPLETED"
                                                ? _Palette.success
                                                .withOpacity(0.12)
                                                : _Palette.primary
                                                .withOpacity(0.10),
                                            borderRadius:
                                            BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: status.toUpperCase() ==
                                                  "COMPLETED"
                                                  ? _Palette.success
                                                  : _Palette.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded,
                                          size: 15,
                                          color: _Palette.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Code: ${aoi['aoi_code']}",
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: _Palette.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.place_outlined,
                                          size: 15,
                                          color: _Palette.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "${aoi['city'] ?? '-'}, ${aoi['state'] ?? '-'}",
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: _Palette.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40,)
                ],
              ),
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
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: _Palette.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Professional Action Card -----------------
  Widget _buildProfessionalActionCard(
      String title,
      IconData icon,
      double screenWidth, {
        VoidCallback? onTap,
      }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: _Palette.primary.withOpacity(0.08),
          highlightColor: _Palette.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Palette.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 26, color: _Palette.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _Palette.textPrimary,
                    height: 1.3,
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
  // (kept for compatibility with any external references)
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