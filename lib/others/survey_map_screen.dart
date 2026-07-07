import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/aoi_provider.dart';
import 'image_crop_screen.dart';

/// Same palette used across the app (dashboard, drawer, profile, AOIs, etc.)
/// so every screen reads as one cohesive, professional design system.
class _Palette {
  static const primary = Color(0xFF4B2FBF);
  static const primaryDark = Color(0xFF37217F);
  static const textPrimary = Color(0xFF1D1B2E);
  static const textSecondary = Color(0xFF6E6B80);

  static const success = Color(0xFF1FA971);
  static const danger = Color(0xFFD7263D);
  static const info = Color(0xFF2E86DE);
  static const disabled = Color(0xFF9E9E9E);
}

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
  bool _isUploading = false;
  bool _isPickingImage = false;
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
          strokeColor: _Palette.primary,
          fillColor: _Palette.primary.withOpacity(0.15),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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

    if (!isInside && !_hasShownOutsideAoiMessage) {
      _hasShownOutsideAoiMessage = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("? You are outside assigned AOI!"),
          backgroundColor: _Palette.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }

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
        SnackBar(
          content: const Text("You must be inside AOI to capture photo"),
          backgroundColor: _Palette.danger,
        ),
      );
      return;
    }

    if (_isPickingImage || _isUploading) return;

    setState(() => _isPickingImage = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo == null) return;

      File originalFile = File(photo.path);

      if (!await originalFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Captured file does not exist"),
            backgroundColor: _Palette.danger,
          ),
        );
        return;
      }

      /// Open crop screen
      Uint8List imageBytes = await originalFile.readAsBytes();

      Uint8List? croppedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(imageData: imageBytes),
        ),
      );

      if (croppedImage == null) return;

      /// Save cropped file
      final croppedFile = File('${photo.path}_cropped.png');
      await croppedFile.writeAsBytes(croppedImage);

      /// Compress image
      File compressedFile = await _compressImage(croppedFile);

      /// Show loading overlay
      setState(() => _isUploading = true);

      /// Start upload
      final provider = context.read<AoiProvider>();

      await provider.uploadPhoto(
        filePath: compressedFile.path,
        aoiId: widget.aoi["id"],
        latitude: _currentLatitude.toString(),
        longitude: _currentLongitude.toString(),
      );

      if (provider.error != null) throw provider.error!;

      _photoCount++;

      /// Get uploaded URL
      String uploadedUrl = compressedFile.path;

      if (provider.myPhotos.isNotEmpty) {
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

      /// Add marker
      final markerId = "photo_${DateTime.now().millisecondsSinceEpoch}";
      final photoPosition = LatLng(_currentLatitude, _currentLongitude);

      setState(() {
        _isUploading = false;
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

      /// Save locally
      await _savePhotoLocally(uploadedUrl, photoPosition);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Photo $_photoCount uploaded successfully ✅"),
          backgroundColor: _Palette.success,
        ),
      );
    } catch (e) {
      debugPrint("Photo upload failed safely: $e");
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Photo upload failed: $e"),
          backgroundColor: _Palette.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
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
  DateTime _lastCameraMove = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Survey Mode",
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
      body: Stack(
        children: [
          /// Map
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
            onCameraMove: (pos) {
              final now = DateTime.now();
              if (now.difference(_lastCameraMove).inMilliseconds < 100) return;
              _lastCameraMove = now;

              final center = pos.target;
              _currentLocation = center;
              _currentLatitude = center.latitude;
              _currentLongitude = center.longitude;

              _markers.removeWhere((m) => m.markerId.value == "user_location");
              _markers.add(
                Marker(
                  markerId: const MarkerId("user_location"),
                  position: center,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                ),
              );

              if (_polygons.isNotEmpty) _checkInsidePolygon(center);
            },
            onMapCreated: (controller) async {
              _controller = controller;
              await _loadSavedPhotos();
            },
          ),

          /// AOI status banner
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: (_isInsideAoi ? _Palette.success : _Palette.danger)
                    .withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isInsideAoi ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isInsideAoi ? "Inside AOI" : "Outside AOI",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Capture button
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: (_isInsideAoi && !_isUploading) ? _capturePhoto : null,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: (_isInsideAoi && !_isUploading)
                        ? const [_Palette.primary, _Palette.primaryDark]
                        : [_Palette.disabled, _Palette.disabled.withOpacity(0.85)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isInsideAoi && !_isUploading)
                          ? _Palette.primary.withOpacity(0.35)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Capture Photo",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Photo counter
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    "$_photoCount",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          /// My location FAB
          Positioned(
            bottom: 140,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location_rounded, color: _Palette.primary),
            ),
          ),

          /// Upload loading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _Palette.primary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Uploading Photo...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _Palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Please wait",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng current = LatLng(position.latitude, position.longitude);

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: current, zoom: 18),
        ),
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _currentLocation = current;
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<File> _compressImage(File file) async {
    final String targetPath = '${file.path}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
  }
}