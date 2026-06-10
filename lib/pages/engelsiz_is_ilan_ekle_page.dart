import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../data/engelsiz_is_catalog.dart';
import '../models/engelsiz_is_model.dart';
import '../features/auth/login_page.dart';

class EngelsizIsIlanEklePage extends StatefulWidget {
  const EngelsizIsIlanEklePage({super.key});

  @override
  State<EngelsizIsIlanEklePage> createState() => _EngelsizIsIlanEklePageState();
}

class _EngelsizIsIlanEklePageState extends State<EngelsizIsIlanEklePage> {
  final DatabaseReference _ref =
  FirebaseDatabase.instance.ref('engelsiz_is/items');

  String selectedType = 'isci_arayan';

  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _contactNameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _whatsC = TextEditingController();

  String? selectedCategory;
  String? selectedCity;

  bool _saving = false;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _contactNameC.dispose();
    _phoneC.dispose();
    _whatsC.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('İlan eklemek için giriş yapmalısın.');
      await _goLogin();
      return;
    }

    final title = _titleC.text.trim();
    final desc = _descC.text.trim();
    final contactName = _contactNameC.text.trim();
    final phone = _phoneC.text.trim();
    final whatsapp = _whatsC.text.trim();

    if (title.isEmpty) {
      _snack('Başlık zorunlu');
      return;
    }

    if (selectedCategory == null || selectedCategory!.isEmpty) {
      _snack('Kategori seç');
      return;
    }

    if (selectedCity == null || selectedCity!.isEmpty) {
      _snack('İl seç');
      return;
    }

    if (desc.isEmpty) {
      _snack('Açıklama zorunlu');
      return;
    }

    if (contactName.isEmpty) {
      _snack('İsim zorunlu');
      return;
    }

    if (phone.isEmpty) {
      _snack('Telefon zorunlu');
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final pushRef = _ref.push();

      final ilan = EngelsizIsModel(
        id: pushRef.key ?? '',
        type: selectedType,
        title: title,
        category: selectedCategory!,
        city: selectedCity!,
        desc: desc,
        contactName: contactName,
        phone: phone,
        whatsapp: whatsapp,
        createdAt: now,
        ownerId: user.uid,
        status: 'active',
      );

      final data = ilan.toMap();

      data['id'] = pushRef.key ?? '';
      data['ownerId'] = user.uid;
      data['userId'] = user.uid;
      data['createdBy'] = user.uid;
      data['status'] = 'active';
      data['createdAt'] = now;

      await pushRef.set(data);

      _snack('İlan eklendi ✅');

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = EngelsizIsCatalog.categories.where((e) => e != 'Tümü').toList();
    final cities = EngelsizIsCatalog.cities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engelsiz İş - İlan Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('İş Arayan'),
                  selected: selectedType == 'is_arayan',
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => selectedType = 'is_arayan'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('İşçi Arayan'),
                  selected: selectedType == 'isci_arayan',
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => selectedType = 'isci_arayan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleC,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Başlık / Pozisyon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori (Meslek)',
                border: OutlineInputBorder(),
              ),
              items: cats
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged:
              _saving ? null : (v) => setState(() => selectedCategory = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: const InputDecoration(
                labelText: 'İl',
                border: OutlineInputBorder(),
              ),
              items: cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged:
              _saving ? null : (v) => setState(() => selectedCity = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descC,
              enabled: !_saving,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactNameC,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'İletişim Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneC,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _whatsC,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (opsiyon)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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