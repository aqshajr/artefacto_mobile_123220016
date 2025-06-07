import 'package:artefacto/pages/menu/detail_temples.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/temple_model.dart';
import '../../service/temple_service.dart';

class LBSMapPage extends StatefulWidget {
  final Temple candi;

  const LBSMapPage({
    super.key,
    required this.candi,
  });

  @override
  State<LBSMapPage> createState() => _LBSMapPageState();
}

class _LBSMapPageState extends State<LBSMapPage> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Position? userPosition;
  LatLng? templeCoords;
  String? _templeAddress;
  List<Temple> nearbyTemples = [];
  bool isLoading = true;
  String? errorMessage;

  static const LatLng _initialCameraPosition = LatLng(-2.548926, 118.0148634);

  final Color primaryColor = const Color(0xff233743);
  final Color accentColor = const Color(0xFFB69574);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (mounted) setState(() => isLoading = true);

    try {
      // Get user location first
      await _getUserLocation();

      // Parse temple coordinates
      _parseTempleCoords();

      if (templeCoords == null) {
        throw 'Koordinat candi tidak tersedia';
      }

      // Get temple address if coordinates are available
      if (templeCoords != null) {
        final address = await _getAddressFromCoords(
            templeCoords!.latitude, templeCoords!.longitude);
        if (mounted) setState(() => _templeAddress = address);
      }

      // Get nearby temples only if we have user position
      if (userPosition != null) {
        var temples = await TempleService.getNearbyTemples(
          latitude: userPosition!.latitude,
          longitude: userPosition!.longitude,
        );
        if (mounted) {
          setState(() {
            nearbyTemples = temples
                .where((t) => t.templeID != widget.candi.templeID)
                .toList();
          });
        }
      }

      // Setup markers after all data is gathered
      if (mounted) {
        setState(() {
          _setupMarkers();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Layanan lokasi dinonaktifkan. Mohon aktifkan GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak. Aplikasi membutuhkan akses lokasi.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen. Mohon ubah pengaturan di Settings.';
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() => userPosition = position);
  }

  void _parseTempleCoords() {
    if (widget.candi.latitude != null && widget.candi.longitude != null) {
      templeCoords = LatLng(widget.candi.latitude!, widget.candi.longitude!);
      return;
    }
    final url = widget.candi.locationUrl;
    if (url == null) return;
    final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) templeCoords = LatLng(lat, lng);
    }
  }

  Future<String> _getAddressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        bool isPlusCode = p.street?.contains('+') ?? false;

        final addressParts = [
          if (!isPlusCode) p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ]
            .where((part) =>
                part != null && part.isNotEmpty && part != 'Jalan Tanpa Nama')
            .toSet()
            .toList();

        return addressParts.isEmpty
            ? "Detail alamat tidak tersedia"
            : addressParts.join(', ');
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Gagal mendapatkan alamat";
  }

  Future<void> _launchMapsUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }

  void _setupMarkers() {
    Set<Marker> newMarkers = {};

    // Add user location marker
    if (userPosition != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(userPosition!.latitude, userPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Add main temple marker
    if (templeCoords != null) {
      newMarkers.add(Marker(
        markerId: MarkerId('temple_${widget.candi.templeID}'),
        position: templeCoords!,
        infoWindow: InfoWindow(
          title: widget.candi.title ?? 'Lokasi Candi',
          snippet: _templeAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Add nearby temples markers
    for (var temple in nearbyTemples) {
      if (temple.latitude != null && temple.longitude != null) {
        newMarkers.add(Marker(
          markerId: MarkerId('nearby_${temple.templeID}'),
          position: LatLng(temple.latitude!, temple.longitude!),
          infoWindow: InfoWindow(
            title: temple.title ?? 'Candi Terdekat',
            snippet: temple.location,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () {
            // Show temple details when marker is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TempleDetailPage(temple: temple),
              ),
            );
          },
        ));
      }
    }

    markers = newMarkers;
  }

  void _animateCameraToBounds() {
    if (mapController == null) return;

    if (templeCoords == null) {
      // If no temple coordinates, center on user location
      if (userPosition != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(userPosition!.latitude, userPosition!.longitude),
            14.0,
          ),
        );
      }
      return;
    }

    // If we have temple coordinates but no user position
    if (userPosition == null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(templeCoords!, 14.0),
      );
      return;
    }

    // If we have both positions, show both
    final bounds = LatLngBounds(
      southwest: LatLng(
        userPosition!.latitude < templeCoords!.latitude
            ? userPosition!.latitude
            : templeCoords!.latitude,
        userPosition!.longitude < templeCoords!.longitude
            ? userPosition!.longitude
            : templeCoords!.longitude,
      ),
      northeast: LatLng(
        userPosition!.latitude > templeCoords!.latitude
            ? userPosition!.latitude
            : templeCoords!.latitude,
        userPosition!.longitude > templeCoords!.longitude
            ? userPosition!.longitude
            : templeCoords!.longitude,
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lokasi Candi',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
                if (!isLoading) _animateCameraToBounds();
              });
            },
            initialCameraPosition: CameraPosition(
              target: templeCoords ?? _initialCameraPosition,
              zoom: 14,
            ),
            markers: markers,
            mapToolbarEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (errorMessage != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (!isLoading && errorMessage == null) _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              if (templeCoords != null) ...[
                if (_templeAddress != null && _templeAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _templeAddress!,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon:
                            const Icon(Icons.map_outlined, color: Colors.white),
                        label: Text('Buka di Maps',
                            style: GoogleFonts.poppins(color: Colors.white)),
                        onPressed: () {
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=${templeCoords!.latitude},${templeCoords!.longitude}';
                          _launchMapsUrl(url);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Candi Terdekat',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (nearbyTemples.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'Tidak ada candi terdekat\ndalam jangkauan 50 km',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nearbyTemples.length,
                  itemBuilder: (context, index) {
                    final temple = nearbyTemples[index];
                    return _buildTempleTile(temple);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTempleTile(Temple temple) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: (temple.imageUrl != null && temple.imageUrl!.isNotEmpty)
            ? Image.network(temple.imageUrl!,
                width: 60, height: 60, fit: BoxFit.cover)
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.account_balance)),
      ),
      title: Text(temple.title ?? 'Tanpa Judul',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text('Ketuk untuk melihat detail',
          style: GoogleFonts.poppins(fontSize: 12)),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TempleDetailPage(temple: temple))),
    );
  }
}
