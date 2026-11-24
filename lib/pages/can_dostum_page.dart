import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ilan_model.dart';
import '../services/user_activity_service.dart';
import 'can_dostum_detay_page.dart';
import 'can_dostum_ilan_ekle_page.dart';

class CanDostumPage extends StatefulWidget {
  const CanDostumPage({super.key});

  @override
  State<CanDostumPage> createState() => _CanDostumPageState();
}

class _CanDostumPageState extends State<CanDostumPage> {
  static const Color _bgColor = Color(0xFFF8F4F6);
  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  final _dbRef = FirebaseDatabase.instance.ref('can_dostum/items');

  String _selectedCategory = 'Tümü';

  static const List<String> _fixedCategories = [
    'Tümü',
    'Kayıp',
    'Sahiplendirme',
    'Yardım',
    'Kedi',
    'Köpek',
    'Kuş',
    'Diğer',
  ];

  static const List<_DemoCanDostumItem> _demoItems = [
    _DemoCanDostumItem(
      id: 'demo_1',
      title: 'Yavru Kediye Sıcak Yuva',
      category: 'Sahiplendirme',
      city: 'Ankara',
      desc: '2 aylık oyuncu ve sağlıklı yavru kedi kalıcı yuvasını arıyor.',
      photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_2',
      title: 'Mama Desteği Aranıyor',
      category: 'Yardım',
      city: 'İstanbul',
      desc: 'Mahalledeki sokak kedileri için kuru mama desteğine ihtiyaç var.',
      photoUrl: 'https://images.unsplash.com/photo-1494256997604-768d1f608cac?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_3',
      title: 'Golden Dostumuz Sahiplendirilecek',
      category: 'Köpek',
      city: 'İzmir',
      desc: 'Aşıları tam, çocuklarla uyumlu, sevgi dolu bir yuva bekliyor.',
      photoUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_4',
      title: 'Kayıp Muhabbet Kuşu',
      category: 'Kayıp',
      city: 'Bursa',
      desc: 'Mavi-beyaz renkli muhabbet kuşu kayboldu. Görenlerin haber vermesi rica olunur.',
      photoUrl: 'https://images.unsplash.com/photo-1522926193341-e9ffd686c60f?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_5',
      title: 'Sokak Köpekleri İçin Su Kabı',
      category: 'Yardım',
      city: 'Antalya',
      desc: 'Sıcak havalarda sokak hayvanları için su kabı ve mama noktası desteği.',
      photoUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_6',
      title: 'Yaralı Kedi İçin Veteriner Desteği',
      category: 'Kedi',
      city: 'Eskişehir',
      desc: 'Arka ayağından yaralanmış kedi için veteriner masrafı desteği aranıyor.',
      photoUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_7',
      title: 'Barınaktan Dost Sahiplendirme',
      category: 'Sahiplendirme',
      city: 'Konya',
      desc: '1 yaşında dişi köpek yeni ailesini bekliyor. Uyumlu ve sakin.',
      photoUrl: 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_8',
      title: 'Kedi Evi Yapımı İçin Destek',
      category: 'Yardım',
      city: 'Samsun',
      desc: 'Kış ayları için sokak kedilerine korunaklı yuvalar hazırlıyoruz.',
      photoUrl: 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_9',
      title: 'Yeni Doğan Yavrular',
      category: 'Kedi',
      city: 'Adana',
      desc: '4 yavru kedi sütten kesildikten sonra sahiplendirilecek.',
      photoUrl: 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=900',
    ),
    _DemoCanDostumItem(
      id: 'demo_10',
      title: 'Pati Dostlarına Mama Noktası',
      category: 'Diğer',
      city: 'Gaziantep',
      desc: 'Mahallede düzenli mama ve su noktası oluşturmak için gönüllü aranıyor.',
      photoUrl: 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=900',
    ),
  ];

  Stream<List<IlanModel>> _getItems() {
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

  List<String> _buildCategories(List<_CanDostumDisplayItem> items) {
    final set = <String>{..._fixedCategories};

    for (final x in items) {
      final c = x.category.trim();
      if (c.isNotEmpty) set.add(c);
    }

    final extras = set.difference(_fixedCategories.toSet()).toList()..sort();
    return [..._fixedCategories, ...extras];
  }

  List<_CanDostumDisplayItem> _buildDisplayItems(List<IlanModel> firebaseItems) {
    if (firebaseItems.isNotEmpty) {
      return firebaseItems.map(_CanDostumDisplayItem.fromIlan).toList();
    }

    return _demoItems.map(_CanDostumDisplayItem.fromDemo).toList();
  }

  void _openDemoDetail(_CanDostumDisplayItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    item.photoUrl ?? '',
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 210,
                      color: Colors.black.withOpacity(0.05),
                      child: const Center(child: Icon(Icons.pets, size: 54)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.category} • ${item.city}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.desc,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Can Dostum'),
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
            MaterialPageRoute(builder: (_) => const CanDostumIlanEklePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<IlanModel>>(
        stream: _getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final firebaseItems = snapshot.data ?? [];
          final items = _buildDisplayItems(firebaseItems);

          final categories = _buildCategories(items);

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'Tümü';
          }

          final filtered = _selectedCategory == 'Tümü'
              ? items
              : items.where((x) => x.category.trim() == _selectedCategory).toList();

          return Column(
            children: [
              const SizedBox(height: 8),
              _CategoryBar(
                categories: categories,
                selected: _selectedCategory,
                onSelect: (c) => setState(() => _selectedCategory = c),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final x = filtered[i];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await UserActiveService.instance.addRecent(
                          module: 'can_dostum',
                          itemId: x.id,
                          payload: {
                            'title': x.title,
                            'subtitle': '${x.category} • ${x.city}',
                            'photo': x.photoUrl ?? '',
                          },
                        );

                        if (!context.mounted) return;

                        if (x.ilan != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CanDostumDetayPage(ilan: x.ilan!),
                            ),
                          );
                        } else {
                          _openDemoDetail(x);
                        }
                      },
                      child: Card(
                        color: _cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: _borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: x.photoUrl == null
                                    ? Container(
                                        width: 82,
                                        height: 82,
                                        color: Colors.black.withOpacity(0.04),
                                        child: const Icon(Icons.pets_outlined),
                                      )
                                    : Image.network(
                                        x.photoUrl!,
                                        width: 82,
                                        height: 82,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 82,
                                          height: 82,
                                          color: Colors.black.withOpacity(0.04),
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEADFE3),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        x.category,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      x.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${x.city} • ${x.desc}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
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

class _CanDostumDisplayItem {
  final String id;
  final String title;
  final String category;
  final String city;
  final String desc;
  final String? photoUrl;
  final IlanModel? ilan;

  const _CanDostumDisplayItem({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.desc,
    required this.photoUrl,
    required this.ilan,
  });

  factory _CanDostumDisplayItem.fromIlan(IlanModel x) {
    return _CanDostumDisplayItem(
      id: x.id,
      title: x.title,
      category: x.category,
      city: x.city,
      desc: x.desc,
      photoUrl: x.photoUrls.isNotEmpty ? x.photoUrls.first : null,
      ilan: x,
    );
  }

  factory _CanDostumDisplayItem.fromDemo(_DemoCanDostumItem x) {
    return _CanDostumDisplayItem(
      id: x.id,
      title: x.title,
      category: x.category,
      city: x.city,
      desc: x.desc,
      photoUrl: x.photoUrl,
      ilan: null,
    );
  }
}

class _DemoCanDostumItem {
  final String id;
  final String title;
  final String category;
  final String city;
  final String desc;
  final String photoUrl;

  const _DemoCanDostumItem({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.desc,
    required this.photoUrl,
  });
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSelected = c == selected;

          return ChoiceChip(
            label: Text(c),
            selected: isSelected,
            onSelected: (_) => onSelect(c),
            selectedColor: const Color(0xFFEADFE3),
            backgroundColor: _cardColor,
            side: BorderSide(color: _borderColor),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : Colors.black87,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}
