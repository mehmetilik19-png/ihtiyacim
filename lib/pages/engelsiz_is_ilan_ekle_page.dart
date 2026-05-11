import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../data/engelsiz_is_catalog.dart';
import '../models/engelsiz_is_model.dart';

class EngelsizIsIlanEklePage extends StatefulWidget {
  const EngelsizIsIlanEklePage({super.key});

  @override
  State<EngelsizIsIlanEklePage> createState() => _EngelsizIsIlanEklePageState();
}

class _EngelsizIsIlanEklePageState extends State<EngelsizIsIlanEklePage> {
  // ✅ RTDB yolu (sende items ise: 'engelsiz_is/items' yap)
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('engelsiz_is/listings');

  // type
  String selectedType = 'isci_arayan'; // is_arayan | isci_arayan

  // form
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Önce giriş yapmalısın');
      return;
    }

    final title = _titleC.text.trim();
    final desc = _descC.text.trim();
    final contactName = _contactNameC.text.trim();
    final phone = _phoneC.text.trim();
    final whatsapp = _whatsC.text.trim();

    if (title.isEmpty) return _snack('Başlık zorunlu');
    if (selectedCategory == null || selectedCategory!.isEmpty) return _snack('Kategori seç');
    if (selectedCity == null || selectedCity!.isEmpty) return _snack('İl seç');
    if (desc.isEmpty) return _snack('Açıklama zorunlu');
    if (contactName.isEmpty) return _snack('İsim zorunlu');
    if (phone.isEmpty) return _snack('Telefon zorunlu');

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

        // ✅ HATALARI BİTİREN KISIM
        ownerId: user.uid,
        status: 'active',
      );

      await pushRef.set(ilan.toMap());

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
      appBar: AppBar(title: const Text('Engelsiz İş - İlan Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // type chip
            Row(
              children: [
                ChoiceChip(
                  label: const Text('İş Arayan'),
                  selected: selectedType == 'is_arayan',
                  onSelected: _saving ? null : (_) => setState(() => selectedType = 'is_arayan'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('İşçi Arayan'),
                  selected: selectedType == 'isci_arayan',
                  onSelected: _saving ? null : (_) => setState(() => selectedType = 'isci_arayan'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _titleC,
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
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedCategory = v),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: const InputDecoration(
                labelText: 'İl',
                border: OutlineInputBorder(),
              ),
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _saving ? null : (v) => setState(() => selectedCity = v),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descC,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _contactNameC,
              decoration: const InputDecoration(
                labelText: 'İletişim Adı',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _phoneC,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _whatsC,
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