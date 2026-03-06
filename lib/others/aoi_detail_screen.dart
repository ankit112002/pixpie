import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pixpie/others/survey_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/aoi_provider.dart';

class AoiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> aoi;
  final List<Map<String, dynamic>> pois;

  const AoiDetailScreen({super.key, required this.aoi, required this.pois});

  @override
  State<AoiDetailScreen> createState() => _AoiDetailScreenState();

  static Widget _statusChip(String text, Color bg, Color textColor) {
    return Container(
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
  }

  static Widget _card({required Widget child}) {
    return Container(
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
  }

  static Widget _detailRow(String title, String value) {
    return Padding(
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
}

class _AoiDetailScreenState extends State<AoiDetailScreen> {
  GoogleMapController? _mapController;
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  late final CameraPosition _initialCamera;


  @override
  void initState() {
    super.initState();
    _loadPolygon();
    Future.microtask(() {
      final aoiId = widget.aoi["id"]?.toString();
      if (aoiId != null) {
        context.read<AoiProvider>().fetchMyUploadedPhotos(aoiId);
      }
    });

    _loadMarkers();
    final centerLat =
        double.tryParse(widget.aoi["center_latitude"] ?? "0") ?? 0;
    final centerLng =
        double.tryParse(widget.aoi["center_longitude"] ?? "0") ?? 0;

    _initialCamera = CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 14,
    );
  }
  bool _isSubmitting = false;
  Future<void> _submitPhotos() async {

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

    setState(() => _isSubmitting = true);

    final provider = context.read<AoiProvider>();
    await provider.submitAoi(widget.aoi["id"]);

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AOI Submitted Successfully ✅"),
        ),
      );

      // 🔥 Update local status immediately
      setState(() {
        widget.aoi["status"] = "SUBMITTED";
      });


      // 🔥 Return true to refresh previous screen
      Navigator.pop(context, true);
    }

    setState(() => _isSubmitting = false);
  }

  void _loadMarkers() {
    for (var poi in widget.pois) {
      final lat = double.tryParse(poi["latitude"] ?? "");
      final lng = double.tryParse(poi["longitude"] ?? "");

      if (lat != null && lng != null) {
        Color markerColor = Colors.orange;

        if (poi["status"] == "VERIFIED") {
          markerColor = Colors.green;
        } else if (poi["status"] == "REJECTED") {
          markerColor = Colors.red;
        }
        _markers.add(
          Marker(
            markerId: MarkerId(poi["id"].toString()),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getHue(markerColor),
            ),
            onTap: () {
              _showPoiBottomSheet(poi);
            },
            infoWindow: InfoWindow(
              title: poi["name"] ?? "POI",
            ),
          ),
        );
      }
    }
  }
  void _showPoiBottomSheet(Map<String, dynamic> poi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poi["name"] ?? "POI",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Text("Status: ${poi["status"] ?? "Unknown"}"),
              const SizedBox(height: 6),
              Text("Latitude: ${poi["latitude"]}"),
              Text("Longitude: ${poi["longitude"]}"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueOrange;
  }
  // void _fitPolygon() {
  //   if (_polygons.isEmpty || _mapController == null) return;
  //
  //   final points = _polygons.first.points;
  //
  //   double minLat = points.first.latitude;
  //   double maxLat = points.first.latitude;
  //   double minLng = points.first.longitude;
  //   double maxLng = points.first.longitude;
  //
  //   for (var point in points) {
  //     if (point.latitude < minLat) minLat = point.latitude;
  //     if (point.latitude > maxLat) maxLat = point.latitude;
  //     if (point.longitude < minLng) minLng = point.longitude;
  //     if (point.longitude > maxLng) maxLng = point.longitude;
  //   }
  //
  //   final bounds = LatLngBounds(
  //     southwest: LatLng(minLat, minLng),
  //     northeast: LatLng(maxLat, maxLng),
  //   );
  //
  //   _mapController!.animateCamera(
  //     CameraUpdate.newLatLngBounds(bounds, 60),
  //   );
  // }
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
  Color _getPhotoStatusColor(String status) {
    switch (status) {
      case "APPROVED":
        return Colors.green;
      case "REJECTED":
        return Colors.red;
      case "RESUBMITTED":
        return Colors.purple;
      case "ASSIGNED":
        return Colors.blue;
      case "PENDING":
      default:
        return Colors.orange;
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
        length: 2,
        child: Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AOI Details",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Row(
        children: [
          /// Sidebar (hide on mobile)
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Back

                  const SizedBox(height: 8),

                  /// Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      if (widget.aoi["status"] == "STARTED")
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : () async {
                              final provider = context.read<AoiProvider>();

                              await provider.fetchMyUploadedPhotos(widget.aoi["id"]);

                              if (provider.myPhotos.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please upload at least one photo before submitting.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSubmitting = true);

                              await provider.submitAoi(widget.aoi["id"]);

                              setState(() {
                                _isSubmitting = false;
                                widget.aoi["status"] = "SUBMITTED";
                              });

                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text("Success"),
                                    ],
                                  ),
                                  content: const Text(
                                    "AOI submitted successfully.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("OK"),
                                    )
                                  ],
                                ),
                              );
                            },
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Submit",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
                      tabs: [
                        Tab(text: "POIs"),
                       // Tab(text: "Photos"),
                      ],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1 → POIs
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

                        // TAB 2 → Photos
                        _photosTab(),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
  Widget _photosTab() {
    return Consumer<AoiProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        final uploadedPhotos = provider.myPhotos;

        if (uploadedPhotos.isEmpty) {
          return const Center(child: Text("No photos uploaded yet."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: uploadedPhotos.length,
          itemBuilder: (context, index) {
            final photo = uploadedPhotos[index];
            final photoUrl = photo["photo_url"] ?? "";

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image)),
              ),
            );
          },
        );
      },
    );
  }
  void _openFullScreen(String imagePath, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: imagePath,
              child: InteractiveViewer(
                child: Image.file(File(imagePath)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
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

  // ===============================
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
      children: [
        _progressCard(completed, pending, rejected, total, progress),
        const SizedBox(height: 16),
        SizedBox(height: 300, child: _mapCard()),
        const SizedBox(height: 16),
        _detailsCard(aoiCode, city, state, assignedUser),
      ],
    );
  }

  // ===============================
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

            // Load polygon if empty
            if (_polygons.isEmpty) {
              _loadPolygon();
            } else {
              // Gather all points from all polygons
              final allPoints = _polygons.expand((p) => p.points).toList();
              _fitPolygon(allPoints);
            }
          },
        ),
      ),
    );
  }
  void _loadPolygon() {
    final geoJson = widget.aoi["boundary_geojson"];
    final List<LatLng> allPoints = [];
    final Set<Polygon> polygons = {};

    if (geoJson != null) {
      // Support Polygon or MultiPolygon
      if (geoJson["type"] == "Polygon") {
        final coords = geoJson["coordinates"];
        if (coords is List) {
          for (var ring in coords) {
            if (ring is List) {
              final points = <LatLng>[];
              for (var pt in ring) {
                if (pt is List && pt.length >= 2) {
                  points.add(LatLng(pt[1], pt[0])); // LatLng(lat, lng)
                }
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
          }
        }
      } else if (geoJson["type"] == "MultiPolygon") {
        final multi = geoJson["coordinates"];
        if (multi is List) {
          for (var poly in multi) {
            if (poly is List && poly.isNotEmpty) {
              final outerRing = poly[0];
              final points = <LatLng>[];
              for (var pt in outerRing) {
                if (pt is List && pt.length >= 2) {
                  points.add(LatLng(pt[1], pt[0]));
                }
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
          }
        }
      }
    }

    if (polygons.isNotEmpty) {
      setState(() {
        _polygons = polygons;
        _markers.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitPolygon(allPoints);
      });
      return;
    }

    // Fallback → center marker
    final centerLat =
        double.tryParse(widget.aoi["center_latitude"]?.toString() ?? "0") ?? 0;
    final centerLng =
        double.tryParse(widget.aoi["center_longitude"]?.toString() ?? "0") ?? 0;
    final centerPoint = LatLng(centerLat, centerLng);

    setState(() {
      _polygons.clear();
      _markers = {
        Marker(
          markerId: const MarkerId("center_marker"),
          position: centerPoint,
          infoWindow: InfoWindow(title: widget.aoi["aoi_name"] ?? "AOI"),
        )
      };
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(centerPoint, 14),
      );
    });
  }
  void _fitPolygon(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
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

          final isSubmitted = widget.aoi["status"] == "SUBMITTED";
          final isStarted = widget.aoi["status"] == "STARTED";

          return ElevatedButton(
            onPressed: isSubmitted || provider.isLoading
                ? null
                : () async {

              if (!isStarted) {
                /// 🔹 START AOI
                await provider.startAoi(widget.aoi["id"]);

                if (provider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error!)),
                  );
                  return;
                }

                /// ✅ UPDATE LOCAL STATUS
                setState(() {
                  widget.aoi["status"] = "STARTED";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("AOI Started Successfully ✅"),
                  ),
                );
              } else {
                /// 🔹 Navigate to Survey Screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyMapScreen(
                      aoi: widget.aoi,
                      pois: widget.pois,
                    ),
                  ),
                );
                if (result == true) {
                  final aoiId = widget.aoi["id"]?.toString();
                  if (aoiId != null) {
                    context.read<AoiProvider>().fetchMyUploadedPhotos(aoiId);
                  }
                }
              }
            },

            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),

            child: provider.isLoading
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
          );
        },
      )
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Column(
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

}
