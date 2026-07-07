import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/api_provider.dart';

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

class UnassignedAoiScreen extends StatefulWidget {
  const UnassignedAoiScreen({super.key});

  @override
  State<UnassignedAoiScreen> createState() =>
      _UnassignedAoiScreenState();
}

class _UnassignedAoiScreenState
    extends State<UnassignedAoiScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<ApiProvider>().getUnAssignedAoi());
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case "HIGH":
        return _Palette.danger;
      case "MEDIUM":
        return _Palette.warning;
      case "LOW":
        return _Palette.success;
      default:
        return _Palette.neutral;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "DRAFT":
        return _Palette.info;
      case "SUBMITTED":
        return _Palette.primary;
      case "CLOSED":
        return _Palette.success;
      default:
        return _Palette.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _Palette.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Unassigned AOI",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
        ),
        centerTitle: true,
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
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _Palette.primary),
            );
          }

          if (provider.error != null) {
            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () async {
                await provider.getUnAssignedAoi();
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
                            "Load Failed",
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
                            width: 160,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => provider.getUnAssignedAoi(),
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

          if (provider.unassignedAoi.isEmpty) {
            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () => provider.getUnAssignedAoi(),
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
                            child: const Icon(Icons.location_off_outlined,
                                size: 56, color: _Palette.primary),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "No Unassigned AOI Found",
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
            onRefresh: () => provider.getUnAssignedAoi(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.unassignedAoi.length,
              itemBuilder: (context, index) {

                final aoi = provider.unassignedAoi[index];

                final isRequested = provider
                    .requestedAoiIds
                    .contains(aoi["id"]);

                final priorityColor = _priorityColor(aoi["priority"]);
                final statusColor = _statusColor(aoi["status"]);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              aoi["aoi_name"] ?? "",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _Palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            color: priorityColor,
                            label: aoi["priority"] ?? "",
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 15, color: _Palette.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "Code: ${aoi["aoi_code"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _Palette.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: _Palette.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${aoi["city"]}, ${aoi["state"]}",
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: _Palette.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTag(
                            color: statusColor,
                            label: aoi["status"] ?? "",
                          ),
                          Flexible(
                            child: Text(
                              "${aoi["center_latitude"]}, ${aoi["center_longitude"]}",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// Request Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRequested
                                ? Colors.grey.shade300
                                : _Palette.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isRequested
                              ? null
                              : () => _showRequestBottomSheet(
                            context,
                            aoi["id"],
                          ),
                          child: Text(
                            isRequested
                                ? "REQUESTED"
                                : "Request This AOI",
                            style: TextStyle(
                              color: isRequested
                                  ? Colors.grey.shade600
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _showRequestBottomSheet(
      BuildContext context, String aoiId) {

    final TextEditingController notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Consumer<ApiProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    "Request This AOI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Why do you want to work on this area?",
                      hintStyle: const TextStyle(color: _Palette.textSecondary),
                      filled: true,
                      fillColor: _Palette.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _Palette.cardBorder),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _Palette.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                        final success = await provider.requestAoi(
                          aoiId: aoiId,
                          requestNotes: notesController.text.trim(),
                        );
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Request Sent Successfully"),
                            ),
                          );
                        }
                      },
                      child: provider.isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Submit Request",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        );
      },
    );
  }
}