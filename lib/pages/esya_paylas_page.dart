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
  static const Color _bgColor = Color(0xFFF4F1E8);
  static const Color _cardColor = Color(0xFFFFFCF4);
  static const Color _primaryColor = Color(0xFF5F7867);
  static const Color _primarySoft = Color(0xFFDDE6DC);
  static const Color _borderColor = Color(0xFFD5DDD2);
  static const Color _textColor = Color(0xFF26352C);
  static const Color _mutedColor = Color(0xFF6D786F);

  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref('esya_paylas/items');

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
      final value = event.snapshot.value;

      if (value == null || value is! Map) {
        return <IlanModel>[];
      }

      final map = Map<dynamic, dynamic>.from(value);
      final list = <IlanModel>[];

      map.forEach((key, itemValue) {
        if (itemValue is Map) {
          list.add(
            IlanModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(itemValue),
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

    if (_selectedMainCategory == 'Tümü') {
      return true;
    }

    final subCategories =
        _categoryMap[_selectedMainCategory] ?? const ['Tümü'];

    if (_selectedSubCategory != 'Tümü') {
      return itemCategory == _selectedSubCategory;
    }

    return subCategories.contains(itemCategory) ||
        itemCategory == _selectedMainCategory;
  }

  bool _matchesTrade(IlanModel item) {
    if (_tradeFilter == _TradeFilter.all) {
      return true;
    }

    final searchableText =
    '${item.title} ${item.desc} ${item.category}'.toLowerCase();

    if (_tradeFilter == _TradeFilter.free) {
      return searchableText.contains('ücretsiz') ||
          searchableText.contains('bedava') ||
          searchableText.contains('veriyorum') ||
          searchableText.contains('hediye');
    }

    if (_tradeFilter == _TradeFilter.swap) {
      return searchableText.contains('takas');
    }

    return true;
  }

  void _selectMainCategory(String category) {
    setState(() {
      _selectedMainCategory = category;
      _selectedSubCategory = 'Tümü';
    });

    Navigator.pop(context);
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Beyaz Eşya':
        return Icons.kitchen_rounded;
      case 'Mobilya':
        return Icons.chair_rounded;
      case 'Elektronik':
        return Icons.devices_rounded;
      case 'Giyim':
        return Icons.checkroom_rounded;
      case 'Mutfak':
        return Icons.restaurant_rounded;
      case 'Kitap':
        return Icons.menu_book_rounded;
      case 'Diğer':
        return Icons.category_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  String _tradeFilterText() {
    switch (_tradeFilter) {
      case _TradeFilter.free:
        return 'Ücretsiz';
      case _TradeFilter.swap:
        return 'Takas';
      case _TradeFilter.all:
        return 'Tümü';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainCategories = _categoryMap.keys.toList();

    final subCategories =
        _categoryMap[_selectedMainCategory] ?? const ['Tümü'];

    return Scaffold(
      backgroundColor: _bgColor,
      drawer: Drawer(
        backgroundColor: _bgColor,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: const BoxDecoration(
                  color: _primaryColor,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Gönülden Paylaş',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Paylaş, takas et, dayanışmayı büyüt.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Burada ihtiyaç fazlası ürünler ücretsiz paylaşılır '
                            'veya başka ihtiyaçlarla takas edilir.',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Paylaşımların gerçekten ihtiyacı olan kişilere '
                            'ulaşmasını önemsiyoruz. Süreci takip ediyoruz.',
                        style: TextStyle(
                          color: _mutedColor,
                          fontSize: 12.5,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(18, 6, 18, 8),
                child: Text(
                  'Paylaşım türü',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              _DrawerFilterTile(
                icon: Icons.apps_rounded,
                title: 'Tümü',
                selected: _tradeFilter == _TradeFilter.all,
                onTap: () {
                  setState(() {
                    _tradeFilter = _TradeFilter.all;
                  });

                  Navigator.pop(context);
                },
              ),

              _DrawerFilterTile(
                icon: Icons.card_giftcard_rounded,
                title: 'Ücretsiz',
                selected: _tradeFilter == _TradeFilter.free,
                onTap: () {
                  setState(() {
                    _tradeFilter = _TradeFilter.free;
                  });

                  Navigator.pop(context);
                },
              ),

              _DrawerFilterTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Takas',
                selected: _tradeFilter == _TradeFilter.swap,
                onTap: () {
                  setState(() {
                    _tradeFilter = _TradeFilter.swap;
                  });

                  Navigator.pop(context);
                },
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Text(
                  'Kategoriler',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              ...mainCategories.map((mainCategory) {
                final selected =
                    mainCategory == _selectedMainCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: _primarySoft,
                    tileColor: _cardColor,
                    leading: Icon(
                      _categoryIcon(mainCategory),
                      color: selected
                          ? _primaryColor
                          : _mutedColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: _borderColor,
                      ),
                    ),
                    title: Text(
                      mainCategory,
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                      Icons.check_circle_rounded,
                      color: _primaryColor,
                    )
                        : null,
                    onTap: () {
                      _selectMainCategory(mainCategory);
                    },
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          _selectedMainCategory == 'Tümü'
              ? 'Gönülden Paylaş'
              : _selectedMainCategory,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                size: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EsyaIlanEklePage(),
            ),
          );
        },
        icon: const Icon(
          Icons.add_photo_alternate_rounded,
        ),
        label: const Text(
          'İlan Ekle',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<IlanModel>>(
        stream: getEsyaIlanlar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'İlanlar alınamadı.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          final items = snapshot.data ?? <IlanModel>[];

          final filteredItems = items
              .where(_matchesCategory)
              .where(_matchesTrade)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedMainCategory != 'Tümü')
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      4,
                    ),
                    itemCount: subCategories.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(width: 8);
                    },
                    itemBuilder: (context, index) {
                      final subCategory =
                      subCategories[index];

                      return _FilterChipButton(
                        text: subCategory,
                        selected: _selectedSubCategory ==
                            subCategory,
                        onTap: () {
                          setState(() {
                            _selectedSubCategory =
                                subCategory;
                          });
                        },
                      );
                    },
                  ),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  _selectedMainCategory == 'Tümü' ? 14 : 6,
                  14,
                  10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedMainCategory == 'Tümü'
                            ? 'Tüm ilanlar'
                            : _selectedSubCategory == 'Tümü'
                            ? _selectedMainCategory
                            : _selectedSubCategory,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primarySoft,
                        borderRadius:
                        BorderRadius.circular(999),
                        border: Border.all(
                          color: _borderColor,
                        ),
                      ),
                      child: Text(
                        _tradeFilterText(),
                        style: const TextStyle(
                          color: _primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredItems.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    100,
                  ),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    final item =
                    filteredItems[index];

                    final cover =
                    item.photoUrls.isNotEmpty
                        ? item.photoUrls.first
                        : null;

                    return InkWell(
                      borderRadius:
                      BorderRadius.circular(18),
                      onTap: () async {
                        await UserActiveService
                            .instance
                            .addRecent(
                          module: 'esya_paylas',
                          itemId: item.id,
                          payload: {
                            'title': item.title,
                            'subtitle':
                            '${item.category} • ${item.city}',
                            'photo': cover ?? '',
                          },
                        );

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              return EsyaIlanDetayPage(
                                ilan: item,
                              );
                            },
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: _cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                          side: const BorderSide(
                            color: _borderColor,
                          ),
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              _CoverImage(
                                imageUrl: cover,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      const TextStyle(
                                        color: _textColor,
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight
                                            .w900,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.category,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                            style:
                                            const TextStyle(
                                              color:
                                              _primaryColor,
                                              fontSize: 12,
                                              fontWeight:
                                              FontWeight
                                                  .w800,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding:
                                          EdgeInsets
                                              .symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '•',
                                            style:
                                            TextStyle(
                                              color:
                                              _mutedColor,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            item.city,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                            style:
                                            const TextStyle(
                                              color:
                                              _mutedColor,
                                              fontSize: 12,
                                              fontWeight:
                                              FontWeight
                                                  .w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    Text(
                                      item.desc,
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      const TextStyle(
                                        color: _mutedColor,
                                        fontSize: 13,
                                        height: 1.3,
                                        fontWeight:
                                        FontWeight
                                            .w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons
                                    .chevron_right_rounded,
                                color: _primaryColor,
                              ),
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

class _CoverImage extends StatelessWidget {
  final String? imageUrl;

  const _CoverImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const width = 82.0;
    const height = 82.0;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE6DC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD5DDD2),
          ),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF5F7867),
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFDDE6DC),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF5F7867),
              size: 30,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          30,
          24,
          110,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD5DDD2),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 68,
                color: Color(0xFF8EA094),
              ),
              SizedBox(height: 14),
              Text(
                'Henüz ilan yok',
                style: TextStyle(
                  color: Color(0xFF26352C),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'İhtiyaç fazlası bir ürünün varsa burada paylaşabilir, '
                    'dayanışmayı büyütebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6D786F),
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
      onSelected: (_) {
        onTap();
      },
      selectedColor: const Color(0xFFDDE6DC),
      backgroundColor: const Color(0xFFFFFCF4),
      side: const BorderSide(
        color: Color(0xFFD5DDD2),
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected
            ? const Color(0xFF395244)
            : const Color(0xFF526158),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DrawerFilterTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerFilterTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        selectedTileColor: const Color(0xFFDDE6DC),
        tileColor: const Color(0xFFFFFCF4),
        leading: Icon(
          icon,
          color: selected
              ? const Color(0xFF5F7867)
              : const Color(0xFF6D786F),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF26352C),
            fontWeight: selected
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        trailing: selected
            ? const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF5F7867),
        )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: Color(0xFFD5DDD2),
          ),
        ),
      ),
    );
  }
}