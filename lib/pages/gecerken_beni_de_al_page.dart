import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/gecerken_model.dart';
import '../services/user_activity_service.dart'; // ✅ EKLENDİ
import 'gecerken_ilan_ekle_page.dart';
import 'gecerken_detay_page.dart';

class GecerkenBeniDeAlPage extends StatelessWidget {
  GecerkenBeniDeAlPage({super.key});

  final _dbRef = FirebaseDatabase.instance.ref('gecerken_beni_de_al/items');

  Stream<List<GecerkenModel>> getIlanlar() {
    return _dbRef.onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <GecerkenModel>[];

      final map = Map<dynamic, dynamic>.from(val as Map);
      final list = <GecerkenModel>[];

      map.forEach((key, value) {
        if (value is Map) {
          list.add(GecerkenModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          ));
        }
      });

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geçerken Beni de Al')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GecerkenIlanEklePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<GecerkenModel>>(
        stream: getIlanlar(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Henüz ilan yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final x = items[i];
              final cover = x.photoUrls.isNotEmpty ? x.photoUrls.first : null;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () async {
                    // ✅ SON BAKTIKLARIM -> geçerken_beni_de_al
                    final title = x.title.isEmpty ? '${x.fromWhere} → ${x.toWhere}' : x.title;

                    await UserActiveService.instance.addRecent(
                      module: 'gecerken_beni_de_al',
                      itemId: x.id,
                      payload: {
                        'title': title,
                        'subtitle': '${x.role} • ${x.city}',
                        'photo': cover ?? '',
                      },
                    );

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GecerkenDetayPage(item: x)),
                    );
                  },
                  leading: cover == null
                      ? const Icon(Icons.directions_car)
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      cover,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(
                    x.title.isEmpty ? '${x.fromWhere} → ${x.toWhere}' : x.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${x.role} • ${x.city}\n${x.fromWhere} → ${x.toWhere}\n${x.note}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}