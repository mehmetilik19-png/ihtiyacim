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

  String _selectedMainCategory = 'Tümü';
  String _selectedSubCategory = 'Tümü';
  _TradeFilter _tradeFilter = _TradeFilter.all;

  final Map<String, List<String>> _categoryMap = const {
    'Tümü': ['Tümü'],
    'Beyaz Eşya': [
      'Tümü',
      'Buzdolabı',
      'Çamaşır Makinesi',
      'Bulaşık Makinesi',
      'Fırın',
      'Ocak',
      'Derin Dondurucu',
    ],
    'Mobilya': [
      'Tümü',
      'Koltuk',
      'Kanepe',
      'Yatak',
      'Masa',
      'Sandalye',
      'Dolap',
    ],
    'Elektronik': [
      'Tümü',
      'Telefon',
      'Tablet',
      'Bilgisayar',
      'Televizyon',
      'Küçük Ev Aleti',
    ],
    'Giyim': [
      'Tümü',
      'Kadın',
      'Erkek',
      'Çocuk',
      'Ayakkabı',
      'Mont',
    ],
    'Mutfak': [
      'Tümü',
      'Tencere',
      'Tabak',
      'Bardak',
      'Çatal Kaşık',
      'Mutfak Robotu',
    ],
    'Kitap': [
      'Tümü',
      'Roman',
      'Ders Kitabı',
      'Çocuk Kitabı',
      'Kırtasiye',
    ],
    'Diğer': [
      'Tümü',
      'Oyuncak',
      'Bebek Ürünü',
      'Spor',
      'Bahçe',
      'Diğer',
    ],
  };

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

  bool _matchesCategory(IlanModel item) {
    final itemCategory = item.category.trim();

    if (_selectedMainCategory == 'Tümü') return true;

    final subs = _categoryMap[_selectedMainCategory] ?? ['Tümü'];

    if (_selectedSubCategory != 'Tümü') {
      return itemCategory == _selectedSubCategory;
    }

    return subs.contains(itemCategory) || itemCategory == _selectedMainCategory;
  }

  @override
  Widget build(BuildContext context) {
    final mainCategories = _categoryMap.keys.toList();
    final subCategories = _categoryMap[_selectedMainCategory] ?? ['Tümü'];

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

          var filtered = items.where(_matchesCategory).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChipButton(
                      text: 'Tümü',
                      selected: _tradeFilter == _TradeFilter.all,
                      onTap: () => setState(() => _tradeFilter = _TradeFilter.all),
                    ),
                    _FilterChipButton(
                      text: 'Ücretsiz',
                      selected: _tradeFilter == _TradeFilter.free,
                      onTap: () => setState(() => _tradeFilter = _TradeFilter.free),
                    ),
                    _FilterChipButton(
                      text: 'Takas',
                      selected: _tradeFilter == _TradeFilter.swap,
                      onTap: () => setState(() => _tradeFilter = _TradeFilter.swap),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: subCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final sub = subCategories[i];
                    return _FilterChipButton(
                      text: sub,
                      selected: _selectedSubCategory == sub,
                      onTap: () {
                        setState(() {
                          _selectedSubCategory = sub;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 108,
                      padding: const EdgeInsets.only(left: 10, bottom: 12),
                      child: ListView.separated(
                        itemCount: mainCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final main = mainCategories[i];
                          final selected = main == _selectedMainCategory;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedMainCategory = main;
                                _selectedSubCategory = 'Tümü';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFEADFE3) : _cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Text(
                                main,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: selected ? Colors.black : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

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
                        padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final x = filtered[i];
                          final cover = x.photoUrls.isNotEmpty
                              ? x.photoUrls.first
                              : null;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFEADFE3),
      backgroundColor: const Color(0xFFFFFAFB),
      side: const BorderSide(color: Color(0xFFEADFE3)),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? Colors.black : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}