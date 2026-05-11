import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ihtiyacim/models/market_listing_model.dart';
import 'package:ihtiyacim/features/market/services/market_cart.dart';

const String ADMIN_EMAIL = 'mehmetilik19@gmail.com';

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
    if (v is double) return v.round();
    return int.tryParse(_s(v)) ?? fallback;
  }

  String tl(int v) => '$v TL';

  bool get _canDelete {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').toLowerCase().trim();
    final uid = user?.uid ?? '';
    final ownerUid = _s(widget.item.attrs['ownerUid']);

    return email == ADMIN_EMAIL.toLowerCase() || (uid.isNotEmpty && uid == ownerUid);
  }

  int oldPriceOf(MarketListingModel x) {
    return _toInt(
      x.oldPrice != 0
          ? x.oldPrice
          : x.attrs['oldPrice'] ??
          x.attrs['old_price'] ??
          x.attrs['eskiFiyat'] ??
          x.attrs['listPrice'],
    );
  }

  String ilanCodeOf(MarketListingModel x) {
    final code = _s(
      x.ilanCode.isNotEmpty
          ? x.ilanCode
          : x.attrs['ilanCode'] ??
          x.attrs['listingCode'] ??
          x.attrs['code'],
    );

    if (code.isNotEmpty) return code;

    final cleanId = x.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final short = cleanId.length > 6
        ? cleanId.substring(cleanId.length - 6).toUpperCase()
        : cleanId.toUpperCase();

    return 'MKT-$short';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    _snack('İlan kodu kopyalandı: $code');
  }

  Future<void> _deleteListing() async {
    if (!_canDelete) {
      _snack('Bu ilanı silme yetkin yok.');
      return;
    }

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

    final id = widget.item.id;

    await Future.wait([
      FirebaseDatabase.instance.ref('market_listings/$id').remove(),
      FirebaseDatabase.instance.ref('market/listings/$id').remove(),
      FirebaseDatabase.instance.ref('listings/market/$id').remove(),
      FirebaseDatabase.instance.ref('gift_designs/$id').remove(),
      FirebaseDatabase.instance.ref('market_comments/$id').remove(),
    ]);

    if (!mounted) return;
    _snack('İlan silindi');
    Navigator.pop(context);
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

    final oldPrice = oldPriceOf(x);
    final hasDiscount = oldPrice > x.price && oldPrice > 0;
    final ilanCode = ilanCodeOf(x);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          if (_canDelete)
            IconButton(
              tooltip: 'İlanı Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteListing,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
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
                if (hasDiscount)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'İNDİRİM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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

          Text(
            x.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDiscount) ...[
                  Text(
                    tl(oldPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  tl(x.price),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: hasDiscount ? 26 : 22,
                    color: hasDiscount ? Colors.green : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _copyCode(ilanCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'İlan Kodu: $ilanCode',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.70),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                _InfoRow(title: 'Durum', value: x.condition == '1el' ? '1. El' : '2. El'),
                _InfoRow(title: 'Şehir', value: x.city),
                _InfoRow(title: 'Kategori', value: x.categoryPath),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 50,
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

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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