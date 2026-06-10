import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../models/can_dostum_model.dart';
import '../services/ai_image_service.dart';
import '../features/auth/login_page.dart';

class CanDostumIlanEklePage extends StatefulWidget {
  const CanDostumIlanEklePage({super.key});

  @override
  State<CanDostumIlanEklePage> createState() => _CanDostumIlanEklePageState();
}

class _CanDostumIlanEklePageState extends State<CanDostumIlanEklePage> {
  final _dbRef = FirebaseDatabase.instance.ref('can_dostum/items');

  final _titleC = TextEditingController();
  final _descC = TextEditingController();

  String? selectedPetType;
  String? selectedSehir;

  static const List<String> petTypes = [
    'Köpek',
    'Kedi',
    'Kuş',
    'Balık',
    'Tavşan',
    'Diğer',
  ];

  static const List<String> sehirler = [
    'Adana','Adıyaman','Afyonkarahisar','Ağrı','Amasya','Ankara','Antalya','Artvin','Aydın','Balıkesir',
    'Bilecik','Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum','Denizli',
    'Diyarbakır','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkari',
    'Hatay','Isparta','Mersin','İstanbul','İzmir','Kars','Kastamonu','Kayseri','Kırklareli','Kırşehir',
    'Kocaeli','Konya','Kütahya','Malatya','Manisa','Kahramanmaraş','Mardin','Muğla','Muş','Nevşehir',
    'Niğde','Ordu','Rize','Sakarya','Samsun','Siirt','Sinop','Sivas','Tekirdağ','Tokat',
    'Trabzon','Tunceli','Şanlıurfa','Uşak','Van','Yozgat','Zonguldak','Aksaray','Bayburt','Karaman',
    'Kırıkkale','Batman','Şırnak','Bartın','Ardahan','Iğdır','Yalova','Karabük','Kilis','Osmaniye','Düzce',
  ];

  final _picker = ImagePicker();
  final _imageService = AiImageService();

  final List<File> _pickedFiles = [];
  bool _saving = false;

  Future<void> _pickMultiImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;
    setState(() {
      _pickedFiles.addAll(images.map((e) => File(e.path)));
    });
  }

  Future<void> _goLogin() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _saveIlan() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _snack('İlan eklemek için giriş yapmalısın.');
      await _goLogin();
      return;
    }

    final title = _titleC.text.trim();
    final desc = _descC.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _snack('Başlık ve açıklama zorunlu.');
      return;
    }
    if (selectedPetType == null) {
      _snack('Hayvan türü seç.');
      return;
    }
    if (selectedSehir == null) {
      _snack('Şehir seç.');
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

      final ilan = CanDostumModel(
        id: ref.key ?? '',
        title: title,
        petType: selectedPetType!,
        city: selectedSehir!,
        desc: desc,
        createdAt: now,
        photoUrls: photoUrls,
      );

      final data = ilan.toMap();
      data['ownerId'] = uid;

      await ref.set(data);

      _snack('İlan eklendi ✅');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Can Dostum İlan Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _titleC,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPetType,
              decoration: const InputDecoration(labelText: 'Hayvan Türü'),
              items: petTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => selectedPetType = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedSehir,
              decoration: const InputDecoration(labelText: 'Şehir'),
              items: sehirler
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => selectedSehir = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descC,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saving ? null : _pickMultiImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Foto Seç (Çoklu)'),
                ),
                const SizedBox(width: 12),
                Text('${_pickedFiles.length} foto'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveIlan,
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