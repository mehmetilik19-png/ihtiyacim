import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ilan_model.dart';
import '../services/ai_image_service.dart';

class EsyaIlanDuzenlePage extends StatefulWidget {
  final IlanModel ilan;
  const EsyaIlanDuzenlePage({super.key, required this.ilan});

  @override
  State<EsyaIlanDuzenlePage> createState() => _EsyaIlanDuzenlePageState();
}

class _EsyaIlanDuzenlePageState extends State<EsyaIlanDuzenlePage> {
  final _dbBase = FirebaseDatabase.instance.ref('esya_paylas/items');

  late final TextEditingController _titleC;
  late final TextEditingController _descC;

  late String selectedKategori;
  late String selectedSehir;

  // ✅ Ücretsiz / Takas
  late String _tradeType; // free | swap

  final _picker = ImagePicker();
  final _imageService = AiImageService();

  final List<File> _newPickedFiles = [];
  bool _saving = false;

  // Mevcut url’ler (ilanın kendi fotoğrafları)
  late List<String> _photoUrls;

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

  @override
  void initState() {
    super.initState();

    _titleC = TextEditingController(text: widget.ilan.title);
    _descC = TextEditingController(text: widget.ilan.desc);

    selectedKategori = widget.ilan.category;
    selectedSehir = widget.ilan.city;
    _tradeType = widget.ilan.tradeType; // free/swap
    _photoUrls = List<String>.from(widget.ilan.photoUrls);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickMultiImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;
    setState(() {
      _newPickedFiles.addAll(images.map((e) => File(e.path)));
    });
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Önce giriş yapmalısın');
      return;
    }
    if (user.uid != widget.ilan.ownerId) {
      _snack('Bu ilanı sadece ilan sahibi düzenleyebilir.');
      return;
    }

    final title = _titleC.text.trim();
    final desc = _descC.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _snack('Başlık ve açıklama zorunlu');
      return;
    }
    if (selectedKategori.trim().isEmpty) {
      _snack('Kategori seç');
      return;
    }
    if (selectedSehir.trim().isEmpty) {
      _snack('Şehir seç');
      return;
    }

    // en az 1 foto kalsın (mevcut + yeni)
    final totalCount = _photoUrls.length + _newPickedFiles.length;
    if (totalCount <= 0) {
      _snack('En az 1 foto olmalı');
      return;
    }

    setState(() => _saving = true);

    try {
      // yeni foto seçildiyse upload et ve url’lere ekle
      if (_newPickedFiles.isNotEmpty) {
        final newUrls = await _imageService.uploadMultiple(_newPickedFiles);
        _photoUrls = [..._photoUrls, ...newUrls];
      }

      final updated = widget.ilan.copyWith(
        title: title,
        desc: desc,
        category: selectedKategori,
        city: selectedSehir,
        photoUrls: _photoUrls,
        tradeType: _tradeType,
      );

      await _dbBase.child(widget.ilan.id).update(updated.toMap());

      _snack('Güncellendi');
      if (mounted) Navigator.pop(context, true); // true => refresh iste
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        const Text('Paylaşım Türü', style: TextStyle(fontWeight: FontWeight.w800)),
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
    // mevcut foto url’lerini basit liste gösterelim, istersen “silme” de eklerim
    return Scaffold(
      appBar: AppBar(title: const Text('İlanı Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleC,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 10),

            _tradeTypeSelector(),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedKategori,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedKategori = v ?? selectedKategori),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedSehir,
              decoration: const InputDecoration(labelText: 'Şehir'),
              items: sehirler.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedSehir = v ?? selectedSehir),
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
                  label: const Text('Foto Ekle (Çoklu)'),
                ),
                const SizedBox(width: 12),
                Text('+${_newPickedFiles.length} yeni foto'),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Mevcut Fotoğraflar', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_photoUrls.isEmpty)
              const Text('Foto yok'),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = _photoUrls[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Değişiklikleri Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}