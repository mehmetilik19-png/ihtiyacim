import 'package:flutter/material.dart';
import '../models/ilan_model.dart';
import '../services/user_activity_service.dart'; // ✅ EKLENDİ

class CanDostumDetayPage extends StatelessWidget {
  final IlanModel ilan;
  const CanDostumDetayPage({super.key, required this.ilan});

  static const Color _bgColor = Color(0xFFF8F4F6);
  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  @override
  Widget build(BuildContext context) {
    final cover = ilan.photoUrls.isNotEmpty ? ilan.photoUrls.first : null;

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
              module: 'can_dostum',
              itemId: ilan.id,
            ),
            builder: (context, snap) {
              final isFav = snap.data ?? false;
              return IconButton(
                tooltip: isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: () async {
                  await UserActiveService.instance.toggleFavorite(
                    module: 'can_dostum',
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
                child: const Icon(Icons.pets_outlined, size: 72),
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