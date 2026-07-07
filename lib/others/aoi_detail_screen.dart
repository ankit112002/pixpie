import 'dart:io';
import 'package:PixPe/others/survey_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/aoi_provider.dart';
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

class AoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> aoi;
  final List<Map<String, dynamic>> pois;

  const AoiDetailScreen({super.key, required this.aoi, required this.pois});

  @override
  State<AoiDetailScreen> createState() => _AoiDetailScreenState();

  // Helper widgets
  static Widget _statusChip(String text, Color bg, Color textColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );

  static Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _Palette.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  static Widget _detailRow(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
                fontSize: 13.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _AoiDetailScreenState extends State<AoiDetailScreen> {
  GoogleMapController? _mapController;
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  late final CameraPosition _initialCamera;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  Future<void> _initMapData() async {
    // Load AOI center
    final centerLat =
        double.tryParse(widget.aoi["center_latitude"] ?? "0") ?? 0;
    final centerLng =
        double.tryParse(widget.aoi["center_longitude"] ?? "0") ?? 0;
    _initialCamera = CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 14,
    );

    // Load polygon & markers
    _loadPolygon();
    _loadMarkers();

    // Refresh AOI and photos
    final apiProvider = context.read<ApiProvider>();
    final aoiProvider = context.read<AoiProvider>();
    await apiProvider.getAoi();

    final List aoiList = apiProvider.data ?? [];
    final updatedAoi = aoiList.firstWhere(
          (e) => e["id"] == widget.aoi["id"],
      orElse: () => widget.aoi,
    );

    setState(() => widget.aoi["status"] = updatedAoi["status"]);

    final aoiId = widget.aoi["id"]?.toString();
    if (aoiId != null) await aoiProvider.fetchMyUploadedPhotos(aoiId);
  }

  void _loadMarkers() {
    _markers.clear();
    for (var poi in widget.pois) {
      final lat = double.tryParse(poi["latitude"] ?? "");
      final lng = double.tryParse(poi["longitude"] ?? "");
      if (lat == null || lng == null) continue;

      Color markerColor = Colors.orange;
      if (poi["status"] == "VERIFIED") markerColor = Colors.green;
      if (poi["status"] == "REJECTED") markerColor = Colors.red;

      _markers.add(
        Marker(
          markerId: MarkerId(poi["id"].toString()),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHue(markerColor)),
          onTap: () => _showPoiBottomSheet(poi),
          infoWindow: InfoWindow(title: poi["name"] ?? "POI"),
        ),
      );
    }
  }

  double _getHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueOrange;
  }

  void _showPoiBottomSheet(Map<String, dynamic> poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
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
            Text(
              poi["name"] ?? "POI",
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _Palette.textPrimary),
            ),
            const SizedBox(height: 12),
            Text("Status: ${poi["status"] ?? "Unknown"}",
                style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5)),
            const SizedBox(height: 6),
            Text("Latitude: ${poi["latitude"]}",
                style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5)),
            Text("Longitude: ${poi["longitude"]}",
                style: const TextStyle(color: _Palette.textSecondary, fontSize: 13.5)),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                backgroundColor: _Palette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _loadPolygon() {
    final geoJson = widget.aoi["boundary_geojson"];
    final Set<Polygon> polygons = {};
    final List<LatLng> allPoints = [];

    if (geoJson != null) {
      if (geoJson["type"] == "Polygon") {
        for (var ring in geoJson["coordinates"] ?? []) {
          final points = <LatLng>[];
          for (var pt in ring) {
            if (pt is List && pt.length >= 2) points.add(LatLng(pt[1], pt[0]));
          }
          if (points.isNotEmpty) {
            polygons.add(
              Polygon(
                polygonId: PolygonId("polygon_${polygons.length}"),
                points: points,
                strokeColor: _Palette.primary,
                strokeWidth: 3,
                fillColor: _Palette.primary.withOpacity(0.15),
              ),
            );
            allPoints.addAll(points);
          }
        }
      } else if (geoJson["type"] == "MultiPolygon") {
        for (var poly in geoJson["coordinates"] ?? []) {
          final outerRing = poly[0];
          final points = <LatLng>[];
          for (var pt in outerRing)
            if (pt is List && pt.length >= 2) points.add(LatLng(pt[1], pt[0]));
          if (points.isNotEmpty) {
            polygons.add(
              Polygon(
                polygonId: PolygonId("polygon_${polygons.length}"),
                points: points,
                strokeColor: _Palette.primary,
                strokeWidth: 3,
                fillColor: _Palette.primary.withOpacity(0.15),
              ),
            );
            allPoints.addAll(points);
          }
        }
      }
    }

    if (polygons.isNotEmpty) {
      setState(() => _polygons = polygons);
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fitPolygon(allPoints),
      );
    }
  }

  void _fitPolygon(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "STARTED":
        return _Palette.warning;
      case "SUBMITTED":
        return _Palette.info;
      case "COMPLETED":
        return _Palette.success;
      default:
        return _Palette.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final aoiName = widget.aoi["aoi_name"] ?? "";
    final aoiCode = widget.aoi["aoi_code"] ?? "";
    final city = widget.aoi["city"] ?? "";
    final state = widget.aoi["state"] ?? "";
    final assignedUser = widget.aoi["assigned_to"]?["name"] ?? "Unassigned";
    final aoiStatus = widget.aoi["status"] ?? "PENDING";

    final completed = widget.pois
        .where((e) => e["status"] == "VERIFIED")
        .length;
    final pending = widget.pois.where((e) => e["status"] == "PENDING").length;
    final rejected = widget.pois.where((e) => e["status"] == "REJECTED").length;
    final total = widget.pois.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: _Palette.background,
        appBar: AppBar(
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshData,
            )
          ],
          title: const Text(
            "AOI Details",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
          ),
        ),
        body: Row(
          children: [
            if (!isMobile)
              Container(
                width: 220,
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _sideNavItem(Icons.home_outlined, "Home"),
                    _sideNavItem(Icons.map_outlined, "AOIs"),
                    _sideNavItem(Icons.account_balance_wallet_outlined, "Earnings"),
                    const Spacer(),
                    _sideNavItem(Icons.logout_rounded, "Sign Out", color: _Palette.danger),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: _Palette.primary,
                onRefresh: _refreshData,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              aoiName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _Palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AoiDetailScreen._statusChip(
                            aoiStatus,
                            _getStatusColor(aoiStatus).withOpacity(0.12),
                            _getStatusColor(aoiStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _Palette.cardBorder),
                        ),
                        child: TabBar(
                          indicatorColor: _Palette.primary,
                          labelColor: _Palette.primary,
                          unselectedLabelColor: _Palette.textSecondary,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                          tabs: const [Tab(text: "POIs")],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            isMobile
                                ? _mobileLayout(
                              aoiCode,
                              city,
                              state,
                              assignedUser,
                              completed,
                              pending,
                              rejected,
                              total,
                              progress,
                            )
                                : _desktopLayout(
                              aoiCode,
                              city,
                              state,
                              assignedUser,
                              completed,
                              pending,
                              rejected,
                              total,
                              progress,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideNavItem(IconData icon, String label, {Color color = _Palette.textPrimary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  // ======================
  Widget _desktopLayout(
      String aoiCode,
      String city,
      String state,
      String assignedUser,
      int completed,
      int pending,
      int rejected,
      int total,
      double progress,
      ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _progressCard(completed, pending, rejected, total, progress),
                const SizedBox(height: 16),
                Expanded(child: _mapCard()),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _detailsCard(aoiCode, city, state, assignedUser),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
      String aoiCode,
      String city,
      String state,
      String assignedUser,
      int completed,
      int pending,
      int rejected,
      int total,
      double progress,
      ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
      children: [
        _progressCard(completed, pending, rejected, total, progress),
        const SizedBox(height: 16),
        SizedBox(height: 300, child: _mapCard()),
        const SizedBox(height: 16),
        _detailsCard(aoiCode, city, state, assignedUser),
      ],
    );
  }

  Widget _progressCard(
      int completed,
      int pending,
      int rejected,
      int total,
      double progress,
      ) {
    return AoiDetailScreen._card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pixpe Progress",
            style: TextStyle(fontWeight: FontWeight.bold, color: _Palette.textPrimary, fontSize: 15.5),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _Palette.background,
              color: _Palette.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric("Completed", completed, _Palette.success),
              _metric("Pending", pending, _Palette.warning),
              _metric("Rejected", rejected, _Palette.danger),
              _metric("Total", total, _Palette.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploadedPhotosGallery() {
    return Consumer<AoiProvider>(
      builder: (context, provider, child) {
        if (provider.isFetchingPhotos) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: CircularProgressIndicator(color: _Palette.primary)),
          );
        }

        if (provider.myPhotos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              "No photos uploaded yet",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Uploaded Photos",
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: _Palette.textPrimary),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.myPhotos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final photo = provider.myPhotos[index];

                final photoId = photo["id"].toString();
                final imageUrl = photo["photo_url"] ?? "";
                final status =
                (photo["status"] ?? "PENDING").toString().toUpperCase();

                Color statusColor = _Palette.warning;
                if (status == "VERIFIED") statusColor = _Palette.success;
                if (status == "REJECTED") statusColor = _Palette.danger;

                return Stack(
                  children: [
                    /// PHOTO
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            child: InteractiveViewer(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Text("Image error",
                                        style: TextStyle(color: Colors.white))),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _Palette.cardBorder),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),

                    /// STATUS BADGE
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// DELETE BUTTON
                    Positioned(
                      top: 6,
                      right: 6,
                      child: provider.isDeleting(photoId)
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : GestureDetector(
                        onTap: () async {
                          await provider.deletePhoto(photoId);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    /// RESUBMIT BUTTON (only if rejected)
                    if (status == "REJECTED")
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: provider.isResubmitting(photoId)
                            ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            backgroundColor: _Palette.warning,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await provider.resubmitPhoto(photoId);
                          },
                          child: const Text(
                            "Resubmit",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshData() async {
    final apiProvider = context.read<ApiProvider>();
    final aoiProvider = context.read<AoiProvider>();

    await apiProvider.getAoi();

    final List aoiList = apiProvider.data ?? [];

    final updatedAoi = aoiList.firstWhere(
          (e) => e["id"].toString() == widget.aoi["id"].toString(),
      orElse: () => widget.aoi,
    );

    setState(() {
      widget.aoi["status"] = updatedAoi["status"];
    });

    final aoiId = widget.aoi["id"]?.toString();
    if (aoiId != null) {
      await aoiProvider.fetchMyUploadedPhotos(aoiId);
    }

    _loadMarkers();
  }

  Widget _mapCard() {
    return AoiDetailScreen._card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: _initialCamera,
          polygons: _polygons,
          markers: _markers,
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            if (_polygons.isNotEmpty)
              _fitPolygon(_polygons.expand((p) => p.points).toList());
          },
        ),
      ),
    );
  }

  Widget _detailsCard(
      String aoiCode,
      String city,
      String state,
      String assignedUser,
      ) {
    return AoiDetailScreen._card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AOI Details",
            style: TextStyle(fontWeight: FontWeight.bold, color: _Palette.textPrimary, fontSize: 15.5),
          ),
          const SizedBox(height: 16),
          AoiDetailScreen._detailRow("AOI Code", aoiCode),
          AoiDetailScreen._detailRow("City", city),
          AoiDetailScreen._detailRow("State", state),
          AoiDetailScreen._detailRow("Assigned To", assignedUser),
          const SizedBox(height: 20),

          Consumer<AoiProvider>(
            builder: (context, provider, child) {
              final apiProvider = context.watch<ApiProvider>();
              final List<dynamic> aoiList = apiProvider.data ?? [];

              final updatedAoi = aoiList.firstWhere(
                    (a) => a["id"].toString() == widget.aoi["id"].toString(),
                orElse: () => widget.aoi,
              );

              final status = updatedAoi["status"]?.toString().toUpperCase() ?? "";
              final isSubmitted = status == "SUBMITTED";
              final isStarted = status == "IN_PROGRESS";

              final totalPois = widget.pois.length;
              final uploadedPhotos = provider.myPhotos.length;

              double progress = totalPois == 0
                  ? 0
                  : (uploadedPhotos / totalPois).clamp(0, 1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// SURVEY PROGRESS
                  const Text(
                    "Survey Progress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: _Palette.background,
                      color: _Palette.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("$uploadedPhotos / $totalPois POIs completed",
                      style: const TextStyle(color: _Palette.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),

                  /// START AOI / START SURVEY
                  ElevatedButton(
                    onPressed: isSubmitted || provider.isLoading
                        ? null
                        : () async {
                      if (!isStarted) {
                        await provider.startAoi(
                          widget.aoi["id"].toString(),
                          context.read<ApiProvider>(),
                        );

                        if (provider.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.error!)),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("AOI Started Successfully"),
                          ),
                        );
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurveyMapScreen(
                              aoi: updatedAoi,
                              pois: widget.pois,
                            ),
                          ),
                        );

                        if (result == true) {
                          final aoiId = updatedAoi["id"].toString();
                          await provider.fetchMyUploadedPhotos(aoiId);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: _Palette.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isStartingAoi
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      isSubmitted
                          ? "Survey Submitted"
                          : isStarted
                          ? "Start Survey"
                          : "Start AOI",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _uploadedPhotosGallery(),
                ],
              );
            },
          ),
          Consumer<AoiProvider>(
            builder: (context, provider, child) {
              final isSubmitting = provider.isSubmittingAoi;
              final isUploading = provider.isUploadingPhoto;
              final isFetching = provider.isFetchingPhotos;
              final isSubmitted = widget.aoi["status"] == "SUBMITTED"; // NEW

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    backgroundColor: (isSubmitting || isUploading || isFetching || isSubmitted)
                        ? Colors.grey.shade300
                        : _Palette.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (isSubmitting || isUploading || isFetching || isSubmitted)
                      ? null
                      : () async {
                    await provider.fetchMyUploadedPhotos(widget.aoi["id"]);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text("Submit AOI", style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text(
                          "Are you sure you want to submit this AOI? "
                              "You will not be able to modify it after submission.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel", style: TextStyle(color: _Palette.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Submit",
                              style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    provider.isSubmittingAoi = true;
                    provider.notifyListeners();

                    await provider.submitAoi(widget.aoi["id"]);

                    provider.isSubmittingAoi = false;
                    provider.notifyListeners();

                    if (provider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.error!)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("AOI Submitted Successfully ?"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {
                        widget.aoi["status"] = "SUBMITTED"; // Mark as submitted
                      });
                      Navigator.pop(context, true);
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    isUploading
                        ? "Uploading Photos..."
                        : isSubmitted
                        ? "AOI Submitted"
                        : "Submit AOI",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) => Column(
    children: [
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: _Palette.textSecondary, fontSize: 12.5),
      ),
    ],
  );
}