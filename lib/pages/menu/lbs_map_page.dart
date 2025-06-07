import 'package:artefacto/pages/menu/detail_temples.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/temple_model.dart';
import '../../model/artifact_model.dart';
import '../../service/artifact_service.dart';
import '../../service/temple_service.dart';
import 'detail_artifact.dart';

enum LbsMode { temples, artifacts }

class LBSMapPage extends StatefulWidget {
  final Temple candi;
  final LbsMode mode;

  const LBSMapPage({
    super.key,
    required this.candi,
    required this.mode,
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
  List<dynamic> nearbyItems = [];
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
    setState(() => isLoading = true);
    try {
      await _getUserLocation();
      _parseTempleCoords();

      if (templeCoords != null) {
        final address = await _getAddressFromCoords(
            templeCoords!.latitude, templeCoords!.longitude);
        setState(() => _templeAddress = address);
      }

      if (userPosition != null) {
        if (widget.mode == LbsMode.temples) {
          var temples = await TempleService.getNearbyTemples(
            latitude: userPosition!.latitude,
            longitude: userPosition!.longitude,
          );
          nearbyItems = temples
              .where((t) => t.templeID != widget.candi.templeID)
              .toList();
        } else if (widget.mode == LbsMode.artifacts) {
          nearbyItems = await ArtifactService.getNearbyArtifacts(
              userPosition!.latitude, userPosition!.longitude);
        }
      }
      _setupMarkers();
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Layanan lokasi dinonaktifkan.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen.';
    }
    userPosition = await Geolocator.getCurrentPosition();
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

        // Cek jika nama jalan adalah "plus code" (contoh: "95VW+WG9")
        bool isPlusCode = p.street?.contains('+') ?? false;

        final addressParts = [
          // Jika bukan plus code, tampilkan nama jalan. Jika ya, lewati.
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
    if (userPosition != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(userPosition!.latitude, userPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (templeCoords != null) {
      newMarkers.add(Marker(
        markerId: MarkerId(widget.candi.templeID.toString()),
        position: templeCoords!,
        infoWindow: InfoWindow(title: widget.candi.title ?? 'Lokasi Candi'),
      ));
    }
    setState(() => markers = newMarkers);
    _animateCameraToBounds();
  }

  void _animateCameraToBounds() {
    if (mapController == null || userPosition == null || templeCoords == null) {
      if (mapController != null && templeCoords != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(templeCoords!, 14.0),
        );
      }
      return;
    }

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
      CameraUpdate.newLatLngBounds(bounds, 60.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.mode == LbsMode.temples
        ? 'Lokasi & Candi Terdekat'
        : 'Lokasi & Artefak Terdekat';

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
              mapController = controller;
              if (!isLoading) _animateCameraToBounds();
            },
            initialCameraPosition: CameraPosition(
              target: templeCoords ?? _initialCameraPosition,
              zoom: 12,
            ),
            markers: markers,
            mapToolbarEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (errorMessage != null)
            Center(
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red))),
          if (!isLoading && errorMessage == null) _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet() {
    String sheetTitle, emptyMessage;
    if (widget.mode == LbsMode.temples) {
      sheetTitle = 'Candi Terdekat';
      emptyMessage = 'Tidak ada candi terdekat\ndalam jangkauan 50 km';
    } else {
      sheetTitle = 'Artefak Terdekat';
      emptyMessage = 'Tidak ada artefak terdekat\ndalam jangkauan 5 km';
    }

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
                  sheetTitle,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (nearbyItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      emptyMessage,
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nearbyItems.length,
                  itemBuilder: (context, index) {
                    final item = nearbyItems[index];
                    if (item is Temple) {
                      return _buildTempleTile(item);
                    } else if (item is Artifact) {
                      return _buildArtifactTile(item);
                    }
                    return const SizedBox.shrink();
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

  Widget _buildArtifactTile(Artifact artifact) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: (artifact.imageUrl != null && artifact.imageUrl!.isNotEmpty)
            ? Image.network(artifact.imageUrl!,
                width: 60, height: 60, fit: BoxFit.cover)
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.inventory_2_outlined)),
      ),
      title: Text(artifact.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text('Candi: ${artifact.templeTitle}',
          style: GoogleFonts.poppins(fontSize: 12)),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ArtifactDetailPage(artifact: artifact))),
    );
  }
}
