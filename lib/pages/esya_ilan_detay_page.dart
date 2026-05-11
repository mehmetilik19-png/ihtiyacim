import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ilan_model.dart';
import '../services/user_activity_service.dart'; // ✅ DOĞRU

class EsyaIlanDetayPage extends StatelessWidget {
  final IlanModel ilan;
  const EsyaIlanDetayPage({super.key, required this.ilan});

  static const Color _bgColor = Color(0xFFF8F4F6);
  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  @override
  Widget build(BuildContext context) {
    final cover = ilan.photoUrls.isNotEmpty ? ilan.photoUrls.first : null;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = ilan.ownerId.isNotEmpty && ilan.ownerId == uid;

    final ref = FirebaseDatabase.instance.ref('esya_paylas/items/${ilan.id}');

    Future<void> deleteIlan() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('İlan silinsin mi?'),
          content: const Text('Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      );

      if (ok != true) return;

      await ref.remove();

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan silindi')),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        backgroundColor: _bgColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // ✅ FAVORİ
          StreamBuilder<bool>(
            stream: UserActiveService.instance.watchFavorite(
              module: 'esya_paylas',
              itemId: ilan.id,
            ),
            builder: (context, snap) {
              final isFav = snap.data ?? false;
              return IconButton(
                tooltip: isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: () async {
                  await UserActiveService.instance.toggleFavorite(
                    module: 'esya_paylas',
                    itemId: ilan.id,
                    payload: {
                      'title': ilan.title,
                      'subtitle': '${ilan.category} • ${ilan.city}',
                      'photo': cover ?? '',
                    },
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFav ? 'Favoriden çıkarıldı' : 'Favorilere eklendi'),
                    ),
                  );
                },
              );
            },
          ),

          // ✅ SAHİPSE SİL
          if (isOwner)
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: deleteIlan,
            ),

          // ✅ DÜZENLE (şimdilik sadece yer tutucu)
          if (isOwner)
            IconButton(
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Düzenleme ekranını sıradaki adımda ekleyeceğiz.')),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: cover == null
                  ? Container(
                color: Colors.black.withOpacity(0.05),
                child: const Icon(Icons.image_outlined, size: 72),
              )
                  : Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            ilan.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tag(text: ilan.category),
              _Tag(text: ilan.city),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Açıklama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  ilan.desc,
                  style: const TextStyle(fontSize: 15, height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (ilan.photoUrls.length > 1) ...[
            const Text(
              'Fotoğraflar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ilan.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = ilan.photoUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      width: 120,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 120, color: Colors.black12),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEADFE3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}