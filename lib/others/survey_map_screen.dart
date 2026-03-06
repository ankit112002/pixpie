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
  bool _isCameraMoved = false;

  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;

  int _photoCount = 0;
  Map<String, String> _photoPaths = {}; // markerId -> image path

  bool _isManuallyDragged = false;
  bool _isFollowingUser = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPolygon();
    _startTracking();
    _loadSavedPhotos(); // 🔥 NEW

  }
  Future<void> _loadSavedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "aoi_${widget.aoi["id"]}_photos";

    List<String> saved = prefs.getStringList(key) ?? [];

    for (int i = 0; i < saved.length; i++) {
      final markerId = "photo_saved_$i";

      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: _currentLocation ?? const LatLng(0, 0),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "Photo ${i + 1}",
            onTap: () => _showImagePreview(saved[i]),
          ),
        ),
      );

      _photoPaths[markerId] = saved[i];
    }

    setState(() {
      _photoCount = saved.length;
    });
  }
  // ===============================
  // Load AOI Polygon
  void _loadPolygon() {
    var geoJson = widget.aoi["boundary_geojson"];
    if (geoJson == null) return;

    // 🔥 If String, decode it
    if (geoJson is String) {
      geoJson = jsonDecode(geoJson);
    }

    final coordinates = geoJson["coordinates"][0];

    List<LatLng> points = coordinates.map<LatLng>((coord) {
      return LatLng(
        (coord[1] as num).toDouble(),
        (coord[0] as num).toDouble(),
      );
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
  void _showImagePreview(String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
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
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  // ===============================
  // Start GPS Tracking
  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
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
    ).listen((Position position) {

      final latLng = LatLng(position.latitude, position.longitude);

      _currentLocation = latLng;
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Move camera only first time
      if (_controller != null && _isFollowingUser) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 18),
        );
        _isFollowingUser = false;
      }

      if (_polygons.isNotEmpty) {
        _checkInsidePolygon(latLng);
      }
    });
  }
  // ===============================
  // Check If Inside AOI
  void _checkInsidePolygon(LatLng point) {
    final polygonPoints = _polygons.first.points;

    bool isInside = _isPointInPolygon(point, polygonPoints);

    setState(() {
      _isInsideAoi = isInside;
    });

    if (!isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ You are outside assigned AOI!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ray Casting Algorithm
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;

    for (int j = 0; j < polygon.length - 1; j++) {
      if (((polygon[j].latitude > point.latitude) !=
          (polygon[j + 1].latitude > point.latitude)) &&
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

  // ===============================
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

    try {
      final provider = context.read<AoiProvider>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading photo...")),
      );

      await provider.uploadPhoto(
        filePath: photo.path,
        aoiId: widget.aoi["id"],       // String UUID
        latitude: _currentLatitude.toString(),    // double
        longitude: _currentLongitude.toString(),  // double
      );

      if (provider.error != null) {
        throw provider.error!;
      }

      // ✅ Increase photo count
      _photoCount++;

      final markerId =
          "photo_${DateTime.now().millisecondsSinceEpoch}";

      final photoPosition =
      LatLng(_currentLatitude, _currentLongitude);

      // ✅ Add photo marker
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: photoPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: "Photo $_photoCount",
              onTap: () => _showImagePreview(photo.path),
            ),
          ),
        );

        _photoPaths[markerId] = photo.path;
      });

      await _savePhotoLocally(photo.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Photo $_photoCount uploaded successfully ✅"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePhotoLocally(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "aoi_${widget.aoi["id"]}_photos";

    List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(path);

    await prefs.setStringList(key, existing);
  }

  // ===============================
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Survey Mode")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _polygons.isNotEmpty
                  ? _polygons.first.points.first
                  : const LatLng(0, 0),
              zoom: 15,
            ),
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,

            onCameraMove: (CameraPosition position) {
              final center = position.target;

              setState(() {
                _currentLocation = center;
                _currentLatitude = center.latitude;
                _currentLongitude = center.longitude;

                _markers.removeWhere(
                        (m) => m.markerId.value == "user_location");

                _markers.add(
                  Marker(
                    markerId: const MarkerId("user_location"),
                    position: center,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                  ),
                );
              });

              if (_polygons.isNotEmpty) {
                _checkInsidePolygon(center);
              }
            },

            onMapCreated: (controller) {
              _controller = controller;
            },
          ),

          Positioned(
            bottom: 30,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Photos: $_photoCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  _isFollowingUser = true;
                  _isManuallyDragged = false; // restore GPS control
                });

                if (_currentLocation != null) {
                  _controller?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 18),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}