import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pixpie/others/survey_map_screen.dart';
import 'package:provider/provider.dart';
import '../provider/aoi_provider.dart';
import '../provider/api_provider.dart';

class AoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> aoi;
  final List<Map<String, dynamic>> pois;

  const AoiDetailScreen({super.key, required this.aoi, required this.pois});

  @override
  State<AoiDetailScreen> createState() => _AoiDetailScreenState();

  // Helper widgets
  static Widget _statusChip(String text, Color bg, Color textColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  static Widget _detailRow(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi["name"] ?? "POI",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Status: ${poi["status"] ?? "Unknown"}"),
            const SizedBox(height: 6),
            Text("Latitude: ${poi["latitude"]}"),
            Text("Longitude: ${poi["longitude"]}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Close"),
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
                strokeColor: Colors.blue,
                strokeWidth: 3,
                fillColor: Colors.blue.withOpacity(0.2),
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
                strokeColor: Colors.blue,
                strokeWidth: 3,
                fillColor: Colors.blue.withOpacity(0.2),
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
        return Colors.orange;
      case "SUBMITTED":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      default:
        return Colors.grey;
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
        backgroundColor: const Color(0xfff5f6fa),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshData,
            )
          ],
          title: const Text(
            "AOI Details",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: Row(
          children: [
            if (!isMobile)
              Container(
                width: 220,
                color: Colors.white,
                child: Column(
                  children: const [
                    SizedBox(height: 40),
                    ListTile(title: Text("Home")),
                    ListTile(title: Text("AOIs")),
                    ListTile(title: Text("Earnings")),
                    Spacer(),
                    ListTile(
                      title: Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            aoiName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AoiDetailScreen._statusChip(
                            aoiStatus,
                            _getStatusColor(aoiStatus).withOpacity(0.2),
                            _getStatusColor(aoiStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TabBar(
                          indicatorColor: Colors.blue,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          tabs: [Tab(text: "POIs")],
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
    return Row(
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
      physics: const AlwaysScrollableScrollPhysics(),      children: [
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric("Completed", completed, Colors.green),
              _metric("Pending", pending, Colors.orange),
              _metric("Rejected", rejected, Colors.red),
              _metric("Total", total, Colors.blue),


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
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.myPhotos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "No photos uploaded yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Uploaded Photos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

                Color statusColor = Colors.orange;
                if (status == "VERIFIED") statusColor = Colors.green;
                if (status == "REJECTED") statusColor = Colors.red;

                return Stack(
                  children: [
                    /// PHOTO
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                const Center(child: Text("Image error")),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),

                    /// STATUS BADGE
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                      top: 5,
                      right: 5,
                      child: provider.isDeleting(photoId)
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                            Icons.delete,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    /// RESUBMIT BUTTON (only if rejected)
                    if (status == "REJECTED")
                      Positioned(
                        bottom: 5,
                        left: 5,
                        right: 5,
                        child: provider.isResubmitting(photoId)
                            ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () async {
                            await provider.resubmitPhoto(photoId);
                          },
                          child: const Text(
                            "Resubmit",
                            style: TextStyle(fontSize: 12),
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
            style: TextStyle(fontWeight: FontWeight.bold),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 6),
                  Text("$uploadedPhotos / $totalPois POIs completed"),
                  const SizedBox(height: 15),

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
                      minimumSize: const Size(double.infinity, 45),
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

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: (isSubmitting || isUploading || isFetching || isSubmitted)
                      ? Colors.grey
                      : Colors.green,
                ),
                onPressed: (isSubmitting || isUploading || isFetching || isSubmitted)
                    ? null
                    : () async {
                  await provider.fetchMyUploadedPhotos(widget.aoi["id"]);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Submit AOI"),
                      content: const Text(
                        "Are you sure you want to submit this AOI? "
                            "You will not be able to modify it after submission.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Submit",
                            style: TextStyle(color: Colors.blue),
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
                        content: Text("AOI Submitted Successfully ✅"),
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
                    : isUploading
                    ? const Text("Uploading Photos...")
                    : isSubmitted
                    ? const Text("AOI Submitted")
                    : const Text("Submit AOI"),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
}