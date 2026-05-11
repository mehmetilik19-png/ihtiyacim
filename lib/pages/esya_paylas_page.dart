import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ilan_model.dart';
import '../services/user_activity_service.dart';
import 'esya_ilan_ekle_page.dart';
import 'esya_ilan_detay_page.dart';

enum _TradeFilter { all, free, swap }

class EsyaPaylasPage extends StatefulWidget {
  const EsyaPaylasPage({super.key});

  @override
  State<EsyaPaylasPage> createState() => _EsyaPaylasPageState();
}

class _EsyaPaylasPageState extends State<EsyaPaylasPage> {
  static const Color _bgColor = Color(0xFFF8F4F6);
  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  final _dbRef = FirebaseDatabase.instance.ref('esya_paylas/items');

  String _selectedCategory = 'Tümü';
  _TradeFilter _tradeFilter = _TradeFilter.all;

  Stream<List<IlanModel>> getEsyaIlanlar() {
    return _dbRef.onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <IlanModel>[];

      final map = Map<dynamic, dynamic>.from(val as Map);
      final list = <IlanModel>[];

      map.forEach((key, value) {
        if (value is Map) {
          list.add(
            IlanModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        }
      });

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  List<String> _buildCategories(List<IlanModel> items) {
    final set = <String>{};
    for (final x in items) {
      final c = x.category.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final cats = set.toList()..sort();
    return ['Tümü', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Gönülden Paylaş'),
        backgroundColor: _bgColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEADFE3),
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EsyaIlanEklePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<IlanModel>>(
        stream: getEsyaIlanlar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          final categories = _buildCategories(items);

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'Tümü';
          }

          // 1) Kategori filtresi (mevcut)
          var filtered = _selectedCategory == 'Tümü'
              ? items
              : items.where((x) => x.category == _selectedCategory).toList();

          // 2) Ücretsiz / Takas filtresi (UI hazır)
          // TODO: IlanModel içinde ücretsiz/takas alanı adını gönder (örn: type / isFree / isSwap)
          // Şu an kırmamak için sadece UI var, filtre uygulamıyoruz.
          // if (_tradeFilter == _TradeFilter.free) { ... }
          // if (_tradeFilter == _TradeFilter.swap) { ... }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ✅ Sosyal metin (slogan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Burada fazlalar ücretsiz paylaşılır\n'
                            'ya da ihtiyaçlarla takas edilir.\n'
                            'Küçük bir paylaşım,\n'
                            'büyük bir dayanışmaya dönüşür.',
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Bu alandaki paylaşımların gerçekten ihtiyacı olana ulaşmasını '
                            'önemsiyoruz. Süreci takip ediyoruz; siz de gönül rahatlığıyla paylaşabilirsiniz.',
                        style: TextStyle(
                          fontSize: 12.8,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Ücretsiz / Takas / Tümü (UI)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _tradeFilter == _TradeFilter.all,
                      onSelected: (_) => setState(() => _tradeFilter = _TradeFilter.all),
                      selectedColor: const Color(0xFFEADFE3),
                      backgroundColor: _cardColor,
                      side: BorderSide(color: _borderColor),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tradeFilter == _TradeFilter.all ? Colors.black : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Ücretsiz'),
                      selected: _tradeFilter == _TradeFilter.free,
                      onSelected: (_) => setState(() => _tradeFilter = _TradeFilter.free),
                      selectedColor: const Color(0xFFEADFE3),
                      backgroundColor: _cardColor,
                      side: BorderSide(color: _borderColor),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tradeFilter == _TradeFilter.free ? Colors.black : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Takas'),
                      selected: _tradeFilter == _TradeFilter.swap,
                      onSelected: (_) => setState(() => _tradeFilter = _TradeFilter.swap),
                      selectedColor: const Color(0xFFEADFE3),
                      backgroundColor: _cardColor,
                      side: BorderSide(color: _borderColor),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tradeFilter == _TradeFilter.swap ? Colors.black : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Kategori chip’leri (seninki aynen)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final selected = c == _selectedCategory;

                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      selectedColor: const Color(0xFFEADFE3),
                      backgroundColor: _cardColor,
                      side: BorderSide(color: _borderColor),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.black : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Liste / boş ekran
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Henüz ilan yok.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'İhtiyaç fazlası bir ürünün varsa,\n'
                              'burada paylaşabilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.black54,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final x = filtered[i];
                    final cover = x.photoUrls.isNotEmpty ? x.photoUrls.first : null;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        // ✅ SON BAKTIKLARIM -> esya_paylas
                        await UserActiveService.instance.addRecent(
                          module: 'esya_paylas',
                          itemId: x.id,
                          payload: {
                            'title': x.title,
                            'subtitle': '${x.category} • ${x.city}',
                            'photo': cover ?? '',
                          },
                        );

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EsyaIlanDetayPage(ilan: x),
                          ),
                        );
                      },
                      child: Card(
                        color: _cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: _borderColor),
                        ),
                        child: ListTile(
                          leading: cover == null
                              ? Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: const Icon(Icons.image_outlined),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              cover,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(
                            x.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${x.category} • ${x.city}\n${x.desc}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}