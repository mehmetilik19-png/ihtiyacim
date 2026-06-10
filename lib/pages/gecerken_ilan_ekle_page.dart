import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gecerken_model.dart';
import '../services/ai_image_service.dart';
import '../features/auth/login_page.dart';

class GecerkenIlanEklePage extends StatefulWidget {
  const GecerkenIlanEklePage({super.key});

  @override
  State<GecerkenIlanEklePage> createState() => _GecerkenIlanEklePageState();
}

class _GecerkenIlanEklePageState extends State<GecerkenIlanEklePage> {
  final _dbRef = FirebaseDatabase.instance.ref('gecerken_beni_de_al/items');

  final _titleC = TextEditingController();
  final _fromC = TextEditingController();
  final _toC = TextEditingController();
  final _noteC = TextEditingController();

  String? selectedRole;
  String? selectedCity;

  static const List<String> roles = ['Sürücü', 'Yolcu'];

  static const List<String> sehirler = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  final _picker = ImagePicker();
  final _imageService = AiImageService();

  final List<File> _pickedFiles = [];
  bool _saving = false;

  Future<void> _goLogin() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _pickMultiImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    setState(() {
      _pickedFiles.addAll(images.map((e) => File(e.path)));
    });
  }

  void _snack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('İlan eklemek için giriş yapmalısın.');
      await _goLogin();
      return;
    }

    final title = _titleC.text.trim();
    final from = _fromC.text.trim();
    final to = _toC.text.trim();
    final note = _noteC.text.trim();

    if (selectedRole == null) {
      _snack('Sürücü/Yolcu seç.');
      return;
    }

    if (selectedCity == null) {
      _snack('Şehir seç.');
      return;
    }

    if (from.isEmpty || to.isEmpty) {
      _snack('Nereden / Nereye zorunlu.');
      return;
    }

    if (_pickedFiles.isEmpty) {
      _snack('En az 1 foto seç.');
      return;
    }

    setState(() => _saving = true);

    try {
      final photoUrls = await _imageService.uploadMultiple(_pickedFiles);

      final ref = _dbRef.push();
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = ref.key ?? '';

      final ilan = GecerkenModel(
        id: id,
        ownerId: user.uid,
        title: title,
        role: selectedRole!,
        city: selectedCity!,
        fromWhere: from,
        toWhere: to,
        note: note,
        createdAt: now,
        photoUrls: photoUrls,
      );

      final data = ilan.toMap();

      data['id'] = id;
      data['ownerId'] = user.uid;
      data['userId'] = user.uid;
      data['createdBy'] = user.uid;
      data['status'] = 'active';
      data['createdAt'] = now;

      await ref.set(data);

      _snack('İlan eklendi ✅');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _fromC.dispose();
    _toC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _titleC,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Başlık (opsiyonel)',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Sürücü / Yolcu'),
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged:
              _saving ? null : (v) => setState(() => selectedRole = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: const InputDecoration(labelText: 'Şehir'),
              items: sehirler
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged:
              _saving ? null : (v) => setState(() => selectedCity = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fromC,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nereden'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _toC,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nereye'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteC,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Not / Açıklama'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saving ? null : _pickMultiImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Foto Seç'),
                ),
                const SizedBox(width: 12),
                Text('${_pickedFiles.length} foto'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}