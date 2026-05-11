import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'tarzim_request_ekle_page.dart';

class TarzimPage extends StatefulWidget {
  const TarzimPage({super.key});

  @override
  State<TarzimPage> createState() => _TarzimPageState();
}

class _TarzimPageState extends State<TarzimPage> {
  // ✅ DEPLOY URL'İN (KESİN)
  static const String backendBase =
      'https://us-central1-birnefes-83798.cloudfunctions.net/tarzimaiComment';

  // ImgBB key (zaten sende var)
  static const String imgbbApiKey = '0faf5f066f8efad06d3d6ca7bc8773c4';

  final _picker = ImagePicker();
  final _descCtrl = TextEditingController();

  String _type = 'Ev';
  XFile? _photo;

  bool _loading = false;

  // opsiyonlar
  bool _friendMode = true;
  bool _addDipNote = true;
  bool _requestEdit = false;

  // sonuçlar
  String? _backendVersion;
  String? _imageUrl;
  String? _editedImageUrl;
  String? _comment;
  String? _suggestion;
  String? _error;

  static const List<String> tarzimTypes = [
    'Kadın',
    'Erkek',
    'Ev',
    'Ofis',
    'Dükkan',
    'Çocuk',
  ];

  void _snack(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _photo = x);
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    setState(() => _photo = x);
  }

  Future<String> _uploadToImgbb(File file) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('image', file.path));

    final res = await req.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode != 200) {
      throw Exception('ImgBB upload failed: $body');
    }

    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final url = jsonMap['data']?['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('ImgBB URL bulunamadı: $body');
    }
    return url;
  }

  Future<void> _fetchBackendVersion() async {
    try {
      final res = await http.get(Uri.parse('$backendBase/version'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      setState(() => _backendVersion = '${data['backend']} v${data['version']}');
    } catch (_) {
      // sessiz geç
    }
  }

  Future<void> _analyze() async {
    if (_photo == null) {
      _snack('Önce foto seç.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _comment = null;
      _suggestion = null;
      _imageUrl = null;
      _editedImageUrl = null;
    });

    try {
      // 1) ImgBB upload
      final url = await _uploadToImgbb(File(_photo!.path));
      setState(() => _imageUrl = url);

      // 2) Backend POST
      final payload = {
        "prompt": _descCtrl.text.trim(),
        "type": _type,
        "imageUrl": url,
        "options": {
          "friendMode": _friendMode,
          "addDipNote": _addDipNote,
          "edit": _requestEdit,
        }
      };

      final res = await http.post(
        Uri.parse(backendBase),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      // 🔥 HTML geldiyse (senin FormatException burada patlıyordu)
      final bodyText = res.body.trimLeft();
      if (bodyText.startsWith("<")) {
        throw Exception("Backend HTML döndürdü (URL yanlış / 404): ${bodyText.substring(0, bodyText.length > 80 ? 80 : bodyText.length)}");
      }

      final data = jsonDecode(res.body);

      if (res.statusCode != 200 || data["ok"] != true) {
        throw Exception(data["error"]?.toString() ?? "Backend hata");
      }

      setState(() {
        _editedImageUrl = data["editedImageUrl"]?.toString();
        _comment = data["comment"]?.toString();
        _suggestion = data["suggestion"]?.toString();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBackendVersion();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final originalFile = _photo != null ? File(_photo!.path) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarzım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TarzimRequestEklePage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Backend Version: ${_backendVersion ?? "yok"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _type,
            items: tarzimTypes
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: _loading ? null : (v) => setState(() => _type = v ?? 'Ev'),
            decoration: const InputDecoration(labelText: 'Kategori'),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _descCtrl,
            minLines: 2,
            maxLines: 4,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Ne istiyorsun?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            title: const Text('Dost modu'),
            value: _friendMode,
            onChanged: _loading ? null : (v) => setState(() => _friendMode = v),
          ),
          SwitchListTile(
            title: const Text('Dipnot ekle'),
            value: _addDipNote,
            onChanged: _loading ? null : (v) => setState(() => _addDipNote = v),
          ),
          SwitchListTile(
            title: const Text('Düzenlenmiş görsel iste (opsiyonel)'),
            value: _requestEdit,
            onChanged: _loading ? null : (v) => setState(() => _requestEdit = v),
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeriden'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: const Icon(Icons.auto_fix_high),
              label: _loading ? const Text('Bekle...') : const Text('Analiz Et'),
            ),
          ),

          const SizedBox(height: 16),

          if (originalFile != null) ...[
            const Text('Orijinal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(originalFile, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ],

          if (_imageUrl != null) ...[
            const Text('Orijinal (yüklenen URL)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SelectableText(_imageUrl!),
            const SizedBox(height: 12),
          ],

          if (_editedImageUrl != null) ...[
            const Text('Düzenlenmiş (şimdilik aynı)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_editedImageUrl!, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ],

          const Text('Yorum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_comment ?? (_error != null ? 'Hata' : '-')),
          const SizedBox(height: 12),

          const Text('Öneri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_suggestion ?? (_error ?? '-')),
        ],
      ),
    );
  }
}