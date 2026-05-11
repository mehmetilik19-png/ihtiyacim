import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ilan_model.dart';
import '../services/ai_image_service.dart';

class EsyaIlanEklePage extends StatefulWidget {
  const EsyaIlanEklePage({super.key});

  @override
  State<EsyaIlanEklePage> createState() => _EsyaIlanEklePageState();
}

class _EsyaIlanEklePageState extends State<EsyaIlanEklePage> {
  final _dbRef = FirebaseDatabase.instance.ref('esya_paylas/items');

  final _titleC = TextEditingController();
  final _descC = TextEditingController();

  String? selectedKategori;
  String? selectedSehir;

  // ✅ YENİ: Ücretsiz / Takas
  String _tradeType = 'free'; // free | swap

  static const List<String> kategoriler = [
    'Mobilya',
    'Beyaz Eşya',
    'Elektronik',
    'Kıyafet',
    'Oyuncak',
    'Kitap',
    'Çocuk Odası',
    'Diğer',
  ];

  static const List<String> sehirler = [
    'Adana','Adıyaman','Afyonkarahisar','Ağrı','Amasya','Ankara','Antalya','Artvin','Aydın',
    'Balıkesir','Bilecik','Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı',
    'Çorum','Denizli','Diyarbakır','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir',
    'Gaziantep','Giresun','Gümüşhane','Hakkari','Hatay','Isparta','Mersin','İstanbul','İzmir',
    'Kars','Kastamonu','Kayseri','Kırklareli','Kırşehir','Kocaeli','Konya','Kütahya','Malatya',
    'Manisa','Kahramanmaraş','Mardin','Muğla','Muş','Nevşehir','Niğde','Ordu','Rize','Sakarya',
    'Samsun','Siirt','Sinop','Sivas','Tekirdağ','Tokat','Trabzon','Tunceli','Şanlıurfa','Uşak',
    'Van','Yozgat','Zonguldak','Aksaray','Bayburt','Karaman','Kırıkkale','Batman','Şırnak',
    'Bartın','Ardahan','Iğdır','Yalova','Karabük','Kilis','Osmaniye','Düzce',
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

  Future<void> _saveIlan() async {
    final title = _titleC.text.trim();
    final desc = _descC.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _snack('Başlık ve açıklama zorunlu');
      return;
    }
    if (selectedKategori == null) {
      _snack('Kategori seç');
      return;
    }
    if (selectedSehir == null) {
      _snack('Şehir seç');
      return;
    }
    if (_pickedFiles.isEmpty) {
      _snack('En az 1 foto seç');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Önce giriş yapmalısın');
      return;
    }

    setState(() => _saving = true);

    try {
      final photoUrls = await _imageService.uploadMultiple(_pickedFiles);

      final ref = _dbRef.push();
      final ilan = IlanModel(
        id: ref.key ?? '',
        title: title,
        category: selectedKategori!,
        city: selectedSehir!,
        desc: desc,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        photoUrls: photoUrls,

        ownerId: user.uid,
        status: 'active',

        // ✅ YENİ: Ücretsiz / Takas
        tradeType: _tradeType,
      );

      await ref.set(ilan.toMap());
      _snack('İlan eklendi');
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

  Widget _tradeTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paylaşım Türü',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: 'free',
                groupValue: _tradeType,
                title: const Text('Ücretsiz'),
                onChanged: _saving ? null : (v) => setState(() => _tradeType = v!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: 'swap',
                groupValue: _tradeType,
                title: const Text('Takas'),
                onChanged: _saving ? null : (v) => setState(() => _tradeType = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _titleC,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 10),

            // ✅ YENİ: Ücretsiz / Takas seçimi
            _tradeTypeSelector(),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedKategori,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: kategoriler
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedKategori = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedSehir,
              decoration: const InputDecoration(labelText: 'Şehir'),
              items: sehirler
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedSehir = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descC,
              enabled: !_saving,
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