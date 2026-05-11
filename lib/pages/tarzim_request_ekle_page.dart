import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class TarzimRequestEklePage extends StatefulWidget {
  const TarzimRequestEklePage({super.key});

  @override
  State<TarzimRequestEklePage> createState() => _TarzimRequestEklePageState();
}

class _TarzimRequestEklePageState extends State<TarzimRequestEklePage> {
  static const String imgbbApiKey = '0faf5f066f8efad06d3d6ca7bc8773c4';

  final _picker = ImagePicker();
  final _descCtrl = TextEditingController();

  String _type = 'Kadın';
  final List<XFile> _photos = [];

  bool _loading = false;

  // İsteğe bağlı ayarlar (ileride admin/AI tarafı kullanır)
  bool _friendMode = true;
  bool _addDipNote = true;
  bool _requestEdit = false;

  final _db = FirebaseDatabase.instance.ref('tarzim/requests');

  static const List<String> tarzimTypes = [
    'Kadın',
    'Erkek',
    'Ev',
    'Ofis',
    'Dükkan',
    'Çocuk',
  ];

  String _normalizeType(String t) {
    // Türkçe karakterleri ASCII’ye indiriyoruz (kadin/dukkan/cocuk)
    final lower = t.trim().toLowerCase();
    return lower
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final merged = [..._photos, ...picked];
    if (merged.length > 5) {
      _snack('En fazla 5 fotoğraf seçebilirsin.');
      return;
    }

    setState(() {
      _photos
        ..clear()
        ..addAll(merged);
    });
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

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    final url = jsonMap['data']?['url']?.toString();

    if (url == null || url.isEmpty) {
      throw Exception('ImgBB URL bulunamadı: $body');
    }

    return url;
  }

  Future<void> _submit() async {
    if (_photos.isEmpty) {
      _snack('En az 1 fotoğraf eklemelisin.');
      return;
    }
    if (_photos.length > 5) {
      _snack('En fazla 5 fotoğraf seçebilirsin.');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1) ImgBB’ye yükle
      final urls = <String>[];
      for (final x in _photos) {
        final url = await _uploadToImgbb(File(x.path));
        urls.add(url);
      }

      // 2) RTDB’ye yaz
      final now = DateTime.now().millisecondsSinceEpoch;
      final pushRef = _db.push();

      await pushRef.set({
        'type': _normalizeType(_type),
        'description': _descCtrl.text.trim(),
        'photoUrls': urls,
        'status': 'free',
        'createdAt': now,
        'userId': 'test', // TODO: auth uid
        // ✅ Bu ayarlar ileride AI/admin tarafında kullanılabilir
        'options': {
          'friendMode': _friendMode,
          'addDipNote': _addDipNote,
          'edit': _requestEdit,
        }
      });

      if (!mounted) return;
      _snack('Tarzım isteği gönderildi ✅');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarzım • İstek Gönder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: tarzimTypes
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _type = v ?? 'Kadın'),
              decoration: const InputDecoration(labelText: 'Tür'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              minLines: 2,
              maxLines: 4,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Kısa açıklama',
                hintText: 'Ne istiyorsun? (ör: 3 elbise arasında kaldım / ev düzeni / saç...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Dost ayarları (isteğe bağlı)
            SwitchListTile(
              title: const Text('Dost modu'),
              subtitle: const Text('Yargılamadan, “gibi/olabilir” diliyle.'),
              value: _friendMode,
              onChanged: _loading ? null : (v) => setState(() => _friendMode = v),
            ),
            SwitchListTile(
              title: const Text('Dip not ekle'),
              subtitle: const Text('Ana öneriyi bozmadan ekstra ihtimal ekler.'),
              value: _addDipNote,
              onChanged: _loading ? null : (v) => setState(() => _addDipNote = v),
            ),
            SwitchListTile(
              title: const Text('Fotoğrafı düzenle (opsiyonel)'),
              subtitle: const Text('Backend destekliyorsa düzenlenmiş görsel ister.'),
              value: _requestEdit,
              onChanged: _loading ? null : (v) => setState(() => _requestEdit = v),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: Text('Foto seç (${_photos.length}/5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_photos.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photos[i].path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
