import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:ihtiyacim/models/market_listing_model.dart';
import 'package:ihtiyacim/features/market/services/market_cart.dart';

class MarketDetayPage extends StatefulWidget {
  final MarketListingModel item;
  const MarketDetayPage({super.key, required this.item});

  @override
  State<MarketDetayPage> createState() => _MarketDetayPageState();
}

class _MarketDetayPageState extends State<MarketDetayPage> {
  int selectedIndex = 0;

  DatabaseReference get _commentsRef =>
      FirebaseDatabase.instance.ref('market_comments/${widget.item.id}');

  String _s(dynamic v) => (v ?? '').toString().trim();

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    return int.tryParse(_s(v)) ?? fallback;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addToCart() {
    MarketCart.add(widget.item, qty: 1);
    _snack('Sepete eklendi ✅');
    setState(() {});
  }

  void _openGallery(List<String> photos, int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullGalleryPage(photos: photos, startIndex: startIndex),
      ),
    );
  }

  Future<void> _addComment() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      _snack('Yorum için giriş yapmalısın.');
      return;
    }

    final textC = TextEditingController();
    int rating = 5;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Yorum Yaz',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _StarPicker(
                  initial: rating,
                  onChanged: (v) => rating = v,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textC,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Yorum',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final t = textC.text.trim();
                      if (t.length < 3) {
                        _snack('Yorum çok kısa.');
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final t = textC.text.trim();
    textC.dispose();

    if (ok != true) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final key = _commentsRef.push().key;
    if (key == null) return;

    await _commentsRef.child(key).set({
      'uid': u.uid,
      'name': (u.displayName ?? u.email ?? 'Kullanıcı'),
      'rating': rating,
      'text': t,
      'createdAt': now,
    });

    _snack('Yorum eklendi ✅');
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.item;
    final photos = x.photoUrls;
    final cover =
    photos.isNotEmpty ? photos[selectedIndex.clamp(0, photos.length - 1)] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Detayı')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          // ✅ Büyük foto (tıkla → tam ekran galeri)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: cover == null
                      ? Container(
                    color: Colors.black.withOpacity(0.04),
                    child: const Center(child: Icon(Icons.image_outlined)),
                  )
                      : InkWell(
                    onTap: () => _openGallery(photos, selectedIndex),
                    child: Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black.withOpacity(0.04),
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),
                if (photos.isNotEmpty)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${selectedIndex + 1}/${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ✅ Thumbnail
          if (photos.length > 1)
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = photos[i];
                  final sel = i == selectedIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => selectedIndex = i),
                    child: Container(
                      width: 74,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? Colors.black : Colors.black.withOpacity(0.10),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black.withOpacity(0.04),
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 14),

          // ✅ Başlık + fiyat
          Text(
            x.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '${x.price} TL',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),

          const SizedBox(height: 14),

          // ✅ Sepete ekle
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'Sepete Ekle',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ✅ Yorumlar + Ortalama + Ekle
          StreamBuilder<DatabaseEvent>(
            stream: _commentsRef.onValue,
            builder: (context, snap) {
              final raw = snap.data?.snapshot.value;
              final list = <Map<dynamic, dynamic>>[];

              if (raw is Map) {
                for (final e in raw.entries) {
                  if (e.value is Map) {
                    list.add(Map<dynamic, dynamic>.from(e.value as Map));
                  }
                }
                list.sort(
                      (a, b) => _toInt(b['createdAt']).compareTo(_toInt(a['createdAt'])),
                );
              }

              final count = list.length;
              final avg = count == 0
                  ? 0.0
                  : list.fold<int>(0, (s, m) => s + _toInt(m['rating'])) / count;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Yorumlar',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const Spacer(),
                      if (count > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              ' ($count)',
                              style: TextStyle(color: Colors.black.withOpacity(0.6)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addComment,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Yorum Yaz'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (count == 0)
                    const Text('Henüz yorum yok.')
                  else
                    Column(
                      children: [for (final m in list) _CommentTile(data: m)],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FullGalleryPage extends StatefulWidget {
  final List<String> photos;
  final int startIndex;
  const _FullGalleryPage({required this.photos, required this.startIndex});

  @override
  State<_FullGalleryPage> createState() => _FullGalleryPageState();
}

class _FullGalleryPageState extends State<_FullGalleryPage> {
  late final PageController _pc = PageController(initialPage: widget.startIndex);
  late int index = widget.startIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${index + 1}/${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => index = i),
        itemBuilder: (_, i) {
          final url = widget.photos[i];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StarPicker extends StatefulWidget {
  final int initial;
  final ValueChanged<int> onChanged;
  const _StarPicker({required this.initial, required this.onChanged});

  @override
  State<_StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<_StarPicker> {
  late int v = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = idx <= v;
        return IconButton(
          onPressed: () {
            setState(() => v = idx);
            widget.onChanged(v);
          },
          icon: Icon(filled ? Icons.star : Icons.star_border),
        );
      }),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  const _CommentTile({required this.data});

  String _s(dynamic v) => (v ?? '').toString().trim();

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    return int.tryParse(_s(v)) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final name = _s(data['name']).isEmpty ? 'Kullanıcı' : _s(data['name']);
    final text = _s(data['text']);
    final rating = _toInt(data['rating']).clamp(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = (i + 1) <= rating;
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.black.withOpacity(0.75), height: 1.2),
          ),
        ],
      ),
    );
  }
}