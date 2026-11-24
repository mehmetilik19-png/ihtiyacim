import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/market_listing_model.dart';
import '../pages/market_cart.dart';
import '../services/market_rtdb_service.dart';
import 'market_ilan_duzenle_page.dart';

const String adminEmail = 'mehmetilik19@gmail.com';

class MarketDetayPage extends StatefulWidget {
  final MarketListingModel item;

  const MarketDetayPage({
    super.key,
    required this.item,
  });

  @override
  State<MarketDetayPage> createState() => _MarketDetayPageState();
}

class _MarketDetayPageState extends State<MarketDetayPage> {
  late MarketListingModel item;
  int selectedIndex = 0;

  late final DatabaseReference _commentsRef;
  late final Stream<DatabaseEvent> _commentsStream;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    _commentsRef =
        FirebaseDatabase.instance.ref('market_comments/${item.id}');
    _commentsStream = _commentsRef.onValue.asBroadcastStream();
  }

  String _s(dynamic value) => (value ?? '').toString().trim();

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_s(value)) ?? fallback;
  }

  bool get _canManage {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').toLowerCase().trim();
    final uid = user?.uid ?? '';
    final ownerUid = _s(item.attrs['ownerUid']);

    return email == adminEmail.toLowerCase() ||
        (uid.isNotEmpty && uid == ownerUid);
  }

  List<String> get _photos => item.photoUrls
      .map((photo) => photo.trim())
      .where((photo) => photo.isNotEmpty)
      .toSet()
      .toList();

  List<String> get _descriptionItems {
    final raw = _s(
      item.attrs['description'] ??
          item.attrs['aciklama'] ??
          item.attrs['productDescription'] ??
          item.attrs['urunBilgileri'],
    );

    if (raw.isEmpty) return const [];

    return raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'[•\n]+'))
        .map(
          (part) => part
              .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim(),
        )
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<MapEntry<String, String>> get _features {
    final result = <MapEntry<String, String>>[];

    void add(String title, dynamic value) {
      final cleaned = _s(value);
      if (cleaned.isEmpty) return;

      if (!result.any(
        (entry) =>
            entry.key.toLowerCase() == title.toLowerCase() &&
            entry.value.toLowerCase() == cleaned.toLowerCase(),
      )) {
        result.add(MapEntry(title, cleaned));
      }
    }

    add('Marka', item.brand);
    add('Durum', item.condition == '1el' ? '1. El' : '2. El');
    add('Şehir', item.city);
    add('Kategori', item.categoryPath);
    add('Materyal', item.attrs['material'] ?? item.attrs['materyal']);
    add('Renk', item.attrs['color'] ?? item.attrs['renk']);
    add('Yükseklik', item.attrs['height'] ?? item.attrs['yukseklik']);
    add('Genişlik', item.attrs['width'] ?? item.attrs['genislik']);
    add('Derinlik', item.attrs['depth'] ?? item.attrs['derinlik']);

    return result;
  }

  String get _ilanCode {
    if (item.ilanCode.trim().isNotEmpty) return item.ilanCode.trim();

    final cleanId = item.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final short = cleanId.length > 6
        ? cleanId.substring(cleanId.length - 6).toUpperCase()
        : cleanId.toUpperCase();
    return 'MKT-$short';
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _ilanCode));
    _snack('İlan kodu kopyalandı: $_ilanCode');
  }

  Future<void> _openEditPage() async {
    if (!_canManage) {
      _snack('Bu ilanı düzenleme yetkin yok.');
      return;
    }

    final updated = await Navigator.push<MarketListingModel>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketIlanDuzenlePage(item: item),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      item = updated;
      if (selectedIndex >= _photos.length) {
        selectedIndex = 0;
      }
    });
  }

  Future<void> _deleteListing() async {
    if (!_canManage) {
      _snack('Bu ilanı silme yetkin yok.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İlan silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await MarketRtdbService().deleteListing(item.id);

      if (!mounted) return;
      _snack('İlan silindi');
      Navigator.pop(context);
    } catch (error) {
      _snack('İlan silinemedi: $error');
    }
  }

  void _addToCart() {
    MarketCart.add(item, qty: 1);
    _snack('Sepete eklendi ✅');
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('Yorum için giriş yapmalısın.');
      return;
    }

    final controller = TextEditingController();
    int rating = 5;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final insets = MediaQuery.of(sheetContext).viewInsets;

        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Yorum Yaz',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _StarPicker(
                  initial: rating,
                  onChanged: (value) => rating = value,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Yorum',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().length < 3) {
                        _snack('Yorum çok kısa.');
                        return;
                      }
                      Navigator.pop(sheetContext, true);
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

    final text = controller.text.trim();
    controller.dispose();

    if (confirmed != true) return;

    final key = _commentsRef.push().key;
    if (key == null) return;

    await _commentsRef.child(key).set({
      'uid': user.uid,
      'name': user.displayName ?? user.email ?? 'Kullanıcı',
      'rating': rating,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    _snack('Yorum eklendi ✅');
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final safeIndex = photos.isEmpty
        ? 0
        : selectedIndex.clamp(0, photos.length - 1);
    final cover = photos.isEmpty ? null : photos[safeIndex];

    final hasDiscount =
        item.oldPrice > item.price && item.oldPrice > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          if (_canManage)
            IconButton(
              tooltip: 'Düzenle',
              onPressed: _openEditPage,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (_canManage)
            IconButton(
              tooltip: 'Sil',
              onPressed: _deleteListing,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _MainImage(
            cover: cover,
            photoCount: photos.length,
            currentIndex: safeIndex,
            hasDiscount: hasDiscount,
            onTap: photos.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _FullGalleryPage(
                          photos: photos,
                          startIndex: safeIndex,
                        ),
                      ),
                    );
                  },
          ),
          if (photos.length > 1)
            _Thumbnails(
              photos: photos,
              selectedIndex: safeIndex,
              onSelected: (index) {
                setState(() => selectedIndex = index);
              },
            ),
          _WhiteSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasDiscount) ...[
                  Text(
                    '${item.oldPrice} TL',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      decorationThickness: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${item.price} TL',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: hasDiscount
                        ? const Color(0xFF16863B)
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _copyCode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'İlan Kodu: $_ilanCode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.62),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Colors.black.withOpacity(0.52),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_descriptionItems.isNotEmpty)
            _WhiteSection(
              child: _ProductInfo(items: _descriptionItems),
            ),
          if (_features.isNotEmpty)
            _WhiteSection(
              child: _ProductFeatures(features: _features),
            ),
          _WhiteSection(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text(
                  'Sepete Ekle',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          _WhiteSection(
            child: StreamBuilder<DatabaseEvent>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Yorumlar yüklenemedi.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                final raw = snapshot.data?.snapshot.value;
                final comments = <Map<dynamic, dynamic>>[];

                if (raw is Map) {
                  for (final entry in raw.entries) {
                    if (entry.value is Map) {
                      comments.add(
                        Map<dynamic, dynamic>.from(entry.value as Map),
                      );
                    }
                  }

                  comments.sort(
                    (a, b) => _toInt(b['createdAt'])
                        .compareTo(_toInt(a['createdAt'])),
                  );
                }

                final count = comments.length;
                final average = count == 0
                    ? 0.0
                    : comments.fold<int>(
                          0,
                          (sum, comment) =>
                              sum + _toInt(comment['rating']),
                        ) /
                        count;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Yorumlar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        if (count > 0) ...[
                          const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${average.toStringAsFixed(1)} ($count)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _addComment,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Yorum Yaz'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (comments.isEmpty)
                      const Text('Henüz yorum yok.')
                    else
                      for (final comment in comments)
                        _CommentTile(data: comment),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteSection extends StatelessWidget {
  final Widget child;

  const _WhiteSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: child,
    );
  }
}

class _MainImage extends StatelessWidget {
  final String? cover;
  final int photoCount;
  final int currentIndex;
  final bool hasDiscount;
  final VoidCallback? onTap;

  const _MainImage({
    required this.cover,
    required this.photoCount,
    required this.currentIndex,
    required this.hasDiscount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: cover == null
                  ? const _ImagePlaceholder()
                  : InkWell(
                      onTap: onTap,
                      child: Image.network(
                        cover!,
                        key: ValueKey('main-$cover'),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            const _ImagePlaceholder(),
                      ),
                    ),
            ),
            if (hasDiscount)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16863B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'İNDİRİM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            if (photoCount > 0)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.48),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1}/$photoCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  final List<String> photos;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _Thumbnails({
    required this.photos,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final photo = photos[index];
            final selected = index == selectedIndex;

            return InkWell(
              onTap: () => onSelected(index),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.orange
                        : Colors.black.withOpacity(0.10),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    photo,
                    key: ValueKey('thumb-$index-$photo'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) =>
                        const _ImagePlaceholder(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        size: 45,
        color: Colors.grey,
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final List<String> items;

  const _ProductInfo({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Bilgileri',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.circle,
                    size: 7,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.18,
                      color: Colors.black.withOpacity(0.74),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductFeatures extends StatelessWidget {
  final List<MapEntry<String, String>> features;

  const _ProductFeatures({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Özellikleri',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (int index = 0; index < features.length; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: index == features.length - 1
                ? null
                : const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFECECEC)),
                    ),
                  ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    features[index].key,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.12,
                      color: Colors.black.withOpacity(0.62),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Text(
                    features[index].value,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FullGalleryPage extends StatefulWidget {
  final List<String> photos;
  final int startIndex;

  const _FullGalleryPage({
    required this.photos,
    required this.startIndex,
  });

  @override
  State<_FullGalleryPage> createState() => _FullGalleryPageState();
}

class _FullGalleryPageState extends State<_FullGalleryPage> {
  late final PageController _controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    _controller = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (value) => setState(() => index = value),
        itemBuilder: (_, imageIndex) {
          final url = widget.photos[imageIndex];

          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                url,
                key: ValueKey('gallery-$imageIndex-$url'),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 54,
                ),
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

  const _StarPicker({
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<_StarPicker> {
  late int value;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;

        return IconButton(
          onPressed: () {
            setState(() => value = starValue);
            widget.onChanged(value);
          },
          icon: Icon(
            starValue <= value ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const _CommentTile({required this.data});

  String _s(dynamic value) => (value ?? '').toString().trim();

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(_s(value)) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final name =
        _s(data['name']).isEmpty ? 'Kullanıcı' : _s(data['name']);
    final text = _s(data['text']);
    final rating = _toInt(data['rating']).clamp(0, 5);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                children: List.generate(
                  5,
                  (index) => Icon(
                    index + 1 <= rating
                        ? Icons.star
                        : Icons.star_border,
                    size: 15,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: TextStyle(
              height: 1.18,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}
