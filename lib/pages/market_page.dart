import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'market_catalog.dart';

import 'package:ihtiyacim/models/market_listing_model.dart';
import 'package:ihtiyacim/features/market/services/market_cart.dart';

import '../services/market_rtdb_service.dart';

import 'market_cart_page.dart';
import 'market_detay_page.dart';
import 'market_ilan_ekle_page.dart';
import 'market_filter_sheet.dart';

const String ADMIN_EMAIL = 'mehmetilik19@gmail.com';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _service = MarketRtdbService();

  String selectedLeft = '1el';
  String selectedSubChip = 'Hepsi';
  MarketFilterResult _filter = const MarketFilterResult();
  bool _showFavoritesOnly = false;

  String _s(dynamic v) => (v ?? '').toString().trim();

  bool get isAdmin {
    final u = FirebaseAuth.instance.currentUser;
    final email = (u?.email ?? '').trim().toLowerCase();
    return email.isNotEmpty && email == ADMIN_EMAIL;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference? get _favRef {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseDatabase.instance.ref('users/$uid/market_favorites');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Stream<Set<String>> streamFavoriteIds() {
    final ref = _favRef;
    if (ref == null) return Stream.value(<String>{});

    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String>{};
      final ids = <String>{};
      raw.forEach((k, v) {
        if (v != null && v != false) ids.add(k.toString());
      });
      return ids;
    });
  }

  Future<void> toggleFavorite(MarketListingModel x) async {
    final ref = _favRef;
    if (ref == null) return;

    final itemRef = ref.child(x.id);
    final snap = await itemRef.get();
    final exists = snap.exists && snap.value != null && snap.value != false;

    if (exists) {
      await itemRef.remove();
    } else {
      final cover = x.photoUrls.isNotEmpty ? x.photoUrls.first : '';
      await itemRef.set({
        'id': x.id,
        'title': x.title,
        'price': x.price,
        'photo': cover,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void addToCart(MarketListingModel x, {int qty = 1}) {
    MarketCart.add(x, qty: qty);
    setState(() {});
    _snack('Sepete eklendi ✅  (${MarketCart.lines.length})');
  }

  // Hediyelik tasarımlar RTDB
  Stream<List<MarketListingModel>> streamGiftDesigns() {
    final ref = FirebaseDatabase.instance.ref('gift_designs');

    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <MarketListingModel>[];

      final list = <MarketListingModel>[];
      raw.forEach((key, value) {
        if (value is Map) {
          list.add(
            MarketListingModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        }
      });

      list.removeWhere((x) => x.attrs['active'] == false);
      return list;
    });
  }

  String getMainOf(MarketListingModel x) {
    if (x.isGift) return 'Hediyelik Eşya';
    final m = _s(x.attrs['main']);
    return m.isNotEmpty ? m : _s(x.categoryMain);
  }

  String getSubOf(MarketListingModel x) {
    if (x.isGift) {
      final t = _s(x.attrs['giftType']);
      if (t.isNotEmpty) return t;
      final sub = _s(x.categorySub);
      return sub.isNotEmpty ? sub : 'Hediyelik';
    }

    final main = getMainOf(x);
    final a = x.attrs;

    if (main == 'Oto Parça') {
      final g = _s(a['group']);
      if (g.isNotEmpty) return g;
      return _s(x.categorySub);
    }

    final sub = _s(a['sub']);
    if (sub.isNotEmpty) return sub;
    return _s(x.categorySub);
  }

  String getBrandOf(MarketListingModel x) {
    if (x.isGift) return '';
    final b = _s(x.attrs['brand']);
    return b.isNotEmpty ? b : _s(x.brand);
  }

  List<String> buildSubChips(List<MarketListingModel> all) {
    const hepsi = 'Hepsi';

    if (selectedLeft == '1el' || selectedLeft == '2el') {
      final filtered = all.where((x) => x.condition == selectedLeft);
      final freq = <String, int>{};
      for (final x in filtered) {
        final s = getSubOf(x);
        if (s.isEmpty) continue;
        freq[s] = (freq[s] ?? 0) + 1;
      }
      final top = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return [hepsi, ...top.take(16).map((e) => e.key)];
    }

    final filtered = all.where((x) => getMainOf(x) == selectedLeft);
    final set = <String>{};
    for (final x in filtered) {
      final s = getSubOf(x);
      if (s.isNotEmpty) set.add(s);
    }

    if (set.isEmpty) {
      final subs = MarketCatalog.categoryMap[selectedLeft] ?? const <String>[];
      return [hepsi, ...subs];
    }

    final chips = set.toList()..sort();
    return [hepsi, ...chips];
  }

  bool pass(MarketListingModel x, Set<String> favIds) {
    if (_showFavoritesOnly && !favIds.contains(x.id)) return false;

    // soldaki durum/ana kategori filtresi
    if (selectedLeft == '1el' || selectedLeft == '2el') {
      if (x.condition != selectedLeft) return false;
    } else {
      if (getMainOf(x) != selectedLeft) return false;
    }

    // üst chip filtresi
    if (selectedSubChip != 'Hepsi') {
      if (getSubOf(x) != selectedSubChip) return false;
    }

    // bottom sheet filtresi
    if ((_filter.main ?? '').isNotEmpty && getMainOf(x) != _filter.main) return false;
    if ((_filter.sub ?? '').isNotEmpty && getSubOf(x) != _filter.sub) return false;

    if (!x.isGift && (_filter.brand ?? '').isNotEmpty) {
      if (getBrandOf(x) != _filter.brand) return false;
    }

    if ((_filter.city ?? '').isNotEmpty && _s(x.city) != _filter.city) return false;
    if (_filter.minPrice != null && x.price < _filter.minPrice!) return false;
    if (_filter.maxPrice != null && x.price > _filter.maxPrice!) return false;

    return true;
  }

  Future<void> openFilterSheet() async {
    final res = await showModalBottomSheet<MarketFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => MarketFilterSheet(initial: _filter),
    );

    if (res != null) setState(() => _filter = res);
  }

  String tl(int v) => '$v TL';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketListingModel>>(
      stream: _service.streamListings(),
      builder: (context, snapListings) {
        if (snapListings.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapListings.hasError) {
          return Scaffold(body: Center(child: Text('Hata: ${snapListings.error}')));
        }

        final normalAll = snapListings.data ?? [];

        return StreamBuilder<List<MarketListingModel>>(
          stream: streamGiftDesigns(),
          builder: (context, snapGifts) {
            final giftsAll = snapGifts.data ?? [];
            final all = <MarketListingModel>[...normalAll, ...giftsAll];

            return StreamBuilder<Set<String>>(
              stream: streamFavoriteIds(),
              builder: (context, snapFavs) {
                final favIds = snapFavs.data ?? <String>{};

                final subs = buildSubChips(all);
                final items = all.where((x) => pass(x, favIds)).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Market'),
                    actions: [
                      IconButton(
                        tooltip: 'Filtrele',
                        onPressed: openFilterSheet,
                        icon: const Icon(Icons.tune),
                      ),
                      IconButton(
                        tooltip: 'Sepet',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MarketCartPage()),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                      ),
                      if (isAdmin)
                        IconButton(
                          tooltip: 'İlan Ekle',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MarketIlanEklePage()),
                            );
                          },
                          icon: const Icon(Icons.add),
                        ),
                    ],
                  ),
                  body: Column(
                    children: [
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: subs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final t = subs[i];
                            final isSel = t == selectedSubChip;
                            return InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setState(() => selectedSubChip = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: isSel ? Colors.black : Colors.transparent,
                                  border: Border.all(color: Colors.black.withOpacity(0.12)),
                                ),
                                child: Row(
                                  children: [
                                    if (isSel) ...[
                                      const Icon(Icons.check, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      t,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isSel ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('İlan bulunamadı.'))
                            : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62, // ✅ overflow fix
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final x = items[i];
                            final cover = x.photoUrls.isNotEmpty ? x.photoUrls.first : null;
                            final isFav = favIds.contains(x.id);
                            final badgeText = x.isGift ? 'Kişiye Özel' : getSubOf(x);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MarketDetayPage(item: x)),
                                ).then((_) => setState(() {}));
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                      color: Colors.black.withOpacity(.07),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ image area now expands (no overflow)
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(18),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: (cover == null || cover.isEmpty)
                                                  ? Container(
                                                color: Colors.black.withOpacity(0.04),
                                                child: const Center(
                                                  child: Icon(Icons.image_outlined),
                                                ),
                                              )
                                                  : Image.network(
                                                cover,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.black.withOpacity(0.04),
                                                  child: const Center(
                                                    child: Icon(Icons.broken_image),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 10,
                                              top: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(999),
                                                  color: Colors.white.withOpacity(0.92),
                                                  border: Border.all(
                                                    color: Colors.black.withOpacity(0.08),
                                                  ),
                                                ),
                                                child: Text(
                                                  badgeText,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 10,
                                              top: 10,
                                              child: InkWell(
                                                onTap: () => toggleFavorite(x),
                                                borderRadius: BorderRadius.circular(999),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(999),
                                                    color: Colors.black.withOpacity(0.35),
                                                  ),
                                                  child: Icon(
                                                    isFav ? Icons.favorite : Icons.favorite_border,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // ✅ bottom area fixed height-ish (no overflow)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            x.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            tl(x.price),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 36,
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => addToCart(x, qty: 1),
                                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                                              label: const Text(
                                                'Sepete Ekle',
                                                style: TextStyle(fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
