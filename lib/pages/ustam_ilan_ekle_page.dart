import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ustam_model.dart';
import '../constants/cities.dart';
import '../services/ai_image_service.dart';
import '../features/auth/login_page.dart';

class UstamIlanEklePage extends StatefulWidget {
  final UstamModel? initial;

  const UstamIlanEklePage({
    super.key,
    this.initial,
  });

  @override
  State<UstamIlanEklePage> createState() => _UstamIlanEklePageState();
}

class _UstamIlanEklePageState extends State<UstamIlanEklePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  late String _city;
  String _job = 'Boyacı';

  final _dbRef = FirebaseDatabase.instance.ref('ustam/items');

  final _picker = ImagePicker();
  final _imageService = AiImageService();
  final List<File> _pickedFiles = [];

  bool _saving = false;

  static const jobs = [
    'Boyacı',
    'Elektrik',
    'Su Tesisatı',
    'Marangoz',
    'Diğer',
  ];

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();

    final cityList = Cities.onlyCities();
    _city = cityList.contains('Ankara') ? 'Ankara' : cityList.first;

    if (widget.initial != null) {
      final u = widget.initial!;

      _titleCtrl.text = u.title;
      _descCtrl.text = u.desc;
      _districtCtrl.text = u.district;

      if (cityList.contains(u.city)) {
        _city = u.city;
      }

      if (jobs.contains(u.job)) {
        _job = u.job;
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _snack('İlan eklemek için giriş yapmalısın.');
      await _goLogin();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEdit && _pickedFiles.isEmpty) {
      _snack('En az 1 foto seç.');
      return;
    }

    setState(() => _saving = true);

    try {
      final oldUrls = widget.initial?.photoUrls ?? <String>[];
      final newUrls = _pickedFiles.isEmpty
          ? <String>[]
          : await _imageService.uploadMultiple(_pickedFiles);

      final mergedUrls = _isEdit ? [...oldUrls, ...newUrls] : newUrls;

      final now = DateTime.now().millisecondsSinceEpoch;
      final id = widget.initial?.id ?? _dbRef.push().key!;

      final model = UstamModel(
        id: id,
        title: _titleCtrl.text.trim(),
        job: _job,
        city: _city,
        district: _districtCtrl.text.trim(),
        desc: _descCtrl.text.trim(),
        ownerId: widget.initial?.ownerId.isNotEmpty == true
            ? widget.initial!.ownerId
            : uid,
        createdAt: widget.initial?.createdAt ?? now,
        photoUrls: mergedUrls,
      );

      final data = model.toMap();
      data['status'] = 'active';

      await _dbRef.child(id).set(data);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cityList = Cities.onlyCities();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'İlan Düzenle' : 'İlan Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Başlık'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Başlık boş olamaz';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _city,
                decoration: const InputDecoration(labelText: 'İl'),
                items: cityList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _city = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _job,
                decoration: const InputDecoration(labelText: 'Meslek'),
                items: jobs
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _job = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'İlçe'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                enabled: !_saving,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Açıklama boş olamaz';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _pickMultiImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Foto Seç'),
                  ),
                  const SizedBox(width: 12),
                  Text('Yeni: ${_pickedFiles.length}'),
                ],
              ),
              const SizedBox(height: 10),
              if (_pickedFiles.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final f = _pickedFiles[i];

                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              f,
                              width: 120,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: InkWell(
                              onTap: _saving
                                  ? null
                                  : () => setState(() {
                                        _pickedFiles.removeAt(i);
                                      }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
