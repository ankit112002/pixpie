import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/aoi_provider.dart';

class SurveyMapScreen extends StatefulWidget {
  final Map<String, dynamic> aoi;
  final List<Map<String, dynamic>> pois;

  const SurveyMapScreen({
    super.key,
    required this.aoi,
    required this.pois,
  });

  @override
  State<SurveyMapScreen> createState() => _SurveyMapScreenState();
}

class _SurveyMapScreenState extends State<SurveyMapScreen> {
  GoogleMapController? _controller;
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;

  bool _isInsideAoi = false;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;

  int _photoCount = 0;
  Map<String, String> _photoPaths = {}; // markerId -> image path

  bool _isFollowingUser = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPolygon();
    _startTracking();
    _loadSavedPhotos();
  }

  /// ===============================
  /// Load saved photos safely
  Future<void> _loadSavedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "aoi_${widget.aoi["id"]}_photos";
    final List<String> saved = prefs.getStringList(key) ?? [];

    final Set<Marker> loadedMarkers = {};
    final Map<String, String> loadedPaths = {};

    debugPrint("Loading saved photos for AOI ${widget.aoi["id"]}, count: ${saved.length}");

    for (int i = 0; i < saved.length; i++) {
      String path = "";
      double lat = 0.0;
      double lng = 0.0;

      try {
        final dynamic data = jsonDecode(saved[i]);
        debugPrint("Decoded saved[$i]: $data (type: ${data.runtimeType})");

        if (data is Map) {
          final mapData = Map<String, dynamic>.from(data);
          path = mapData["photo_url"]?.toString() ?? mapData["path"]?.toString() ?? "";
          lat = (mapData["lat"] as num?)?.toDouble() ?? 0.0;
          lng = (mapData["lng"] as num?)?.toDouble() ?? 0.0;
        } else if (data is String) {
          path = data;
          if (_polygons.isNotEmpty) {
            lat = _polygons.first.points.first.latitude;
            lng = _polygons.first.points.first.longitude;
          }
        } else {
          debugPrint("Unknown type in saved photo: ${data.runtimeType}");
        }
      } catch (e) {
        // fallback for raw string
        path = saved[i];
        debugPrint("Failed to decode saved[$i], fallback to raw string: $path | $e");
        if (_polygons.isNotEmpty) {
          lat = _polygons.first.points.first.latitude;
          lng = _polygons.first.points.first.longitude;
        }
      }

      if (path.isEmpty) continue;

      final markerId = "photo_saved_$i";
      loadedMarkers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Photo ${i + 1}",
            onTap: () => _showImagePreview(path),
          ),
        ),
      );

      loadedPaths[markerId] = path;
    }

    setState(() {
      _markers.addAll(loadedMarkers);
      _photoPaths = loadedPaths;
      _photoCount = loadedMarkers.length;
    });

    debugPrint("Loaded $_photoCount saved photos successfully");
  }
  /// ===============================
  /// Load AOI Polygon
  void _loadPolygon() {
    var geoJson = widget.aoi["boundary_geojson"];
    if (geoJson == null) return;

    if (geoJson is String) geoJson = jsonDecode(geoJson);

    final coordinates = geoJson["coordinates"][0];
    final points = (coordinates as List).map<LatLng>((coord) {
      return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
    }).toList();

    setState(() {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId("aoi"),
          points: points,
          strokeWidth: 3,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
    });
  }

  /// ===============================
  /// Show captured photo
  void _showImagePreview(String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Captured Photo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: path.startsWith("http")
                  ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    "Failed to load image",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
                  : Image.file(
                File(path),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// Start GPS tracking
  Future<void> _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _currentLocation = latLng;
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      if (_controller != null && _isFollowingUser) {
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 18));
        _isFollowingUser = false;
      }

      if (_polygons.isNotEmpty) _checkInsidePolygon(latLng);
    });
  }

  /// ===============================
  /// Check if inside AOI
  bool _hasShownOutsideAoiMessage = false;

  void _checkInsidePolygon(LatLng point) {
    final polygonPoints = _polygons.first.points;
    bool isInside = _isPointInPolygon(point, polygonPoints);

    // Only show message if user just exited the AOI
    if (!isInside && !_hasShownOutsideAoiMessage) {
      _hasShownOutsideAoiMessage = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ You are outside assigned AOI!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Reset flag when user comes back inside
    if (isInside) {
      _hasShownOutsideAoiMessage = false;
    }

    setState(() => _isInsideAoi = isInside);
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (((polygon[j].latitude > point.latitude) != (polygon[j + 1].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j + 1].longitude - polygon[j].longitude) *
                  (point.latitude - polygon[j].latitude) /
                  (polygon[j + 1].latitude - polygon[j].latitude) +
                  polygon[j].longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  /// ===============================
  /// Capture photo safely
  Future<void> _capturePhoto() async {
    if (!_isInsideAoi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be inside AOI to capture photo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;

    final provider = context.read<AoiProvider>();

    if (!await File(photo.path).exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Captured file does not exist"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading photo...")),
    );

    try {
      // Upload photo
      await provider.uploadPhoto(
        filePath: photo.path,
        aoiId: widget.aoi["id"],
        latitude: _currentLatitude.toString(),
        longitude: _currentLongitude.toString(),
      );

      if (provider.error != null) throw provider.error!;

      _photoCount++;

      // ✅ Use the **latest upload response** safely
      String uploadedUrl = photo.path; // fallback local path
      if (provider.myPhotos.isNotEmpty) {
        // Try to find the photo with the **same file size or timestamp** if possible
        final Map<String, dynamic>? lastUploaded = provider.myPhotos.lastWhere(
              (p) =>
          p is Map &&
              p["aoi_id"] == widget.aoi["id"] &&
              (p["latitude"]?.toString() == _currentLatitude.toString() &&
                  p["longitude"]?.toString() == _currentLongitude.toString()),
          orElse: () => null,
        ) as Map<String, dynamic>?;

        if (lastUploaded != null && lastUploaded["photo_url"] != null) {
          uploadedUrl = lastUploaded["photo_url"].toString();
        }
      }

      final markerId = "photo_${DateTime.now().millisecondsSinceEpoch}";
      final photoPosition = LatLng(_currentLatitude, _currentLongitude);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: photoPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: "Photo $_photoCount",
              onTap: () => _showImagePreview(uploadedUrl),
            ),
          ),
        );
        _photoPaths[markerId] = uploadedUrl;
      });

      await _savePhotoLocally(uploadedUrl, photoPosition);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo $_photoCount uploaded successfully ✅")),
      );
    } catch (e) {
      debugPrint("Photo upload failed safely: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Photo upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  /// ===============================
  /// Save photo locally safely
  Future<void> _savePhotoLocally(String path, LatLng position) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "aoi_${widget.aoi["id"]}_photos";

    List<String> existing = prefs.getStringList(key) ?? [];
    final photoData = jsonEncode({
      "path": path,
      "lat": position.latitude,
      "lng": position.longitude,
      "timestamp": DateTime.now().toIso8601String(),
    });

    existing.add(photoData);
    await prefs.setStringList(key, existing);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// ===============================
  /// Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Survey Mode")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _polygons.isNotEmpty ? _polygons.first.points.first : const LatLng(0, 0),
              zoom: 15,
            ),
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (pos) {
              final center = pos.target;
              _currentLocation = center;
              _currentLatitude = center.latitude;
              _currentLongitude = center.longitude;

              _markers.removeWhere((m) => m.markerId.value == "user_location");
              _markers.add(
                Marker(
                  markerId: const MarkerId("user_location"),
                  position: center,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              );

              if (_polygons.isNotEmpty) _checkInsidePolygon(center);
            },
            onMapCreated: (controller) async {
              _controller = controller;
              await _loadSavedPhotos();
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _isInsideAoi ? _capturePhoto : null,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: _isInsideAoi
                        ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
                        : const [Color(0xFFB0B0B0), Color(0xFF9E9E9E)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Capture Survey Photo",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: Text(
                "Photos: $_photoCount",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}