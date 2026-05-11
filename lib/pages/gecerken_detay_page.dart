import 'package:flutter/material.dart';
import '../models/gecerken_model.dart';
import '../services/user_activity_service.dart'; // ✅ EKLENDİ

class GecerkenDetayPage extends StatelessWidget {
  final GecerkenModel item;
  const GecerkenDetayPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final photos = item.photoUrls;
    final cover = photos.isNotEmpty ? photos.first : null;
    final title = item.title.isEmpty ? '${item.fromWhere} → ${item.toWhere}' : item.title;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        actions: [
          // ✅ FAVORİ
          StreamBuilder<bool>(
            stream: UserActiveService.instance.watchFavorite(
              module: 'gecerken_beni_de_al',
              itemId: item.id,
            ),
            builder: (context, snap) {
              final isFav = snap.data ?? false;
              return IconButton(
                tooltip: isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: () async {
                  await UserActiveService.instance.toggleFavorite(
                    module: 'gecerken_beni_de_al',
                    itemId: item.id,
                    payload: {
                      'title': title,
                      'subtitle': '${item.role} • ${item.city}',
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
        padding: const EdgeInsets.all(12),
        children: [
          if (photos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, i) {
                    return Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 48)),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
            ),

          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: item.role),
              _Chip(text: item.city),
              _Chip(text: 'Foto: ${photos.length}'),
            ],
          ),

          const SizedBox(height: 14),
          _RowInfo(label: 'Nereden', value: item.fromWhere),
          _RowInfo(label: 'Nereye', value: item.toWhere),

          const SizedBox(height: 14),
          const Text('Not', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(item.note.isEmpty ? 'Not yok.' : item.note, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  const _RowInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    );
  }
}