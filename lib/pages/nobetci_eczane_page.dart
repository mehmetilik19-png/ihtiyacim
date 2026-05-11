import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NobetciEczanePage extends StatefulWidget {
  const NobetciEczanePage({super.key});

  @override
  State<NobetciEczanePage> createState() => _NobetciEczanePageState();
}

class _NobetciEczanePageState extends State<NobetciEczanePage> {
  // NosyAPI Key (seninki)
  static const String _apiKey =
      'JB7MBKhstjvSFoyi9s7rCQYvRfYddrNOb3ymDwRSjmxwRNXbGEu1RStZrzwm';

  GoogleMapController? _mapController;

  bool _loading = true;
  String? _error;

  LatLng? _currentLatLng;

  // API’den gelen eczaneler (ham data)
  List<dynamic> _items = [];

  // Harita pinleri
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  // 18:00 - 08:00 kontrolü (istersen kaldırabilirsin)
  bool _allowedTime() {
    final h = DateTime.now().hour;
    return true;
  }

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
      _markers.clear();
    });

    if (!_allowedTime()) {
      setState(() {
        _loading = false;
        _error = 'Nöbetçi eczaneler 18:00 - 08:00 arasında gösterilir.';
      });
      return;
    }

    try {
      final pos = await _getLocation();
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      // Konuma odaklan
      _moveCamera(_currentLatLng!, 14);

      // Kullanıcı konum marker'ı (isteğe bağlı)
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Konumum'),
        ),
      );

      await _loadPharmacies(pos.latitude, pos.longitude);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _moveCamera(LatLng target, double zoom) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  Future<void> _loadPharmacies(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.nosyapi.com/apiv2/service/pharmacies-on-duty/locations'
          '?latitude=$lat&longitude=$lng',
    );

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      },
    );

    final body = jsonDecode(res.body);

    if (body['status'] != 'success') {
      throw Exception('API hata verdi: ${body['message'] ?? 'Bilinmiyor'}');
    }

    final data = (body['data'] as List).cast<dynamic>();

    // Mesafe hesapla, en yakınları üstte göstermek için sırala
    for (final e in data) {
      final pLat = _toDouble(e['latitude']);
      final pLng = _toDouble(e['longitude']);
      if (pLat != null && pLng != null && _currentLatLng != null) {
        final d = Geolocator.distanceBetween(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
          pLat,
          pLng,
        );
        e['_distance'] = d; // metre
      } else {
        e['_distance'] = double.infinity;
      }
    }

    data.sort((a, b) =>
        (a['_distance'] as double).compareTo((b['_distance'] as double)));

    setState(() {
      _items = data;
    });

    // Marker’ları bas
    _markers.removeWhere((m) => m.markerId.value.startsWith('ph_'));

    for (int i = 0; i < _items.length; i++) {
      final e = _items[i];
      final pLat = _toDouble(e['latitude']);
      final pLng = _toDouble(e['longitude']);

      // Bazı API’lerde lat/lng boş gelebilir, o zaman marker basmayız
      if (pLat == null || pLng == null) continue;

      final id = 'ph_$i';
      final name = (e['pharmacyName'] ?? 'Eczane').toString();
      final address = (e['address'] ?? '').toString();

      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(pLat, pLng),
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
            onTap: () {
              // Marker info penceresine dokununca yol tarifi aç
              _openDirections(pLat, pLng, name);
            },
          ),
          onTap: () {
            // Marker’a basınca harita oraya yaklaşsın
            _moveCamera(LatLng(pLat, pLng), 15);
          },
        ),
      );
    }

    setState(() {});

    // En yakına otomatik yaklaş (isteğe bağlı)
    final first = _items.isNotEmpty ? _items.first : null;
    final fLat = first == null ? null : _toDouble(first['latitude']);
    final fLng = first == null ? null : _toDouble(first['longitude']);
    if (fLat != null && fLng != null) {
      _moveCamera(LatLng(fLat, fLng), 14.5);
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Konum kapalı (GPS aç)');
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      throw Exception('Konum izni yok');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _openDirections(double lat, double lng, String label) async {
    // Google Maps uygulamasında yol tarifi
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Google Maps açılamadı');
    }
  }

  String _formatDistance(dynamic d) {
    if (d == null || d is! double || d.isInfinite) return '';
    if (d < 1000) return '${d.toStringAsFixed(0)} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng ?? const LatLng(39.92077, 32.85411), // Ankara
        zoom: 12,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentLatLng != null) {
          _moveCamera(_currentLatLng!, 14);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbetçi Eczaneler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initAll,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Stack(
        children: [
          Positioned.fill(child: map),

          // Altta liste paneli
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 2,
                      color: Colors.black26,
                    ),
                  ],
                ),
                height: min(320, MediaQuery.of(context).size.height * 0.38),
                child: _items.isEmpty
                    ? const Center(child: Text('Eczane bulunamadı'))
                    : ListView.builder(
                  itemCount: min(_items.length, 12), // ekranda 12 göster
                  itemBuilder: (c, i) {
                    final e = _items[i];
                    final name =
                    (e['pharmacyName'] ?? 'Eczane').toString();
                    final address = (e['address'] ?? '').toString();
                    final d = e['_distance'] as double?;
                    final pLat = _toDouble(e['latitude']);
                    final pLng = _toDouble(e['longitude']);

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                        address.isEmpty ? 'Adres yok' : address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(_formatDistance(d)),
                      onTap: () {
                        if (pLat == null || pLng == null) return;
                        // Haritada oraya yaklaş
                        _moveCamera(LatLng(pLat, pLng), 15);
                        // Yol tarifi aç
                        _openDirections(pLat, pLng, name);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentLatLng == null
          ? null
          : FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () => _moveCamera(_currentLatLng!, 14),
      ),
    );
  }
}