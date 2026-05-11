import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ilan_model.dart';
import '../services/user_activity_service.dart'; // ✅ EKLENDİ
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

  List<String> _buildCategories(List<IlanModel> items) {
    final set = <String>{..._fixedCategories};

    for (final x in items) {
      final c = x.category.trim();
      if (c.isNotEmpty) set.add(c);
    }

    final extras = set.difference(_fixedCategories.toSet()).toList()..sort();
    return [..._fixedCategories, ...extras];
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

          final items = snapshot.data ?? [];
          final categories = _buildCategories(items);

          if (!categories.contains(_selectedCategory)) _selectedCategory = 'Tümü';

          if (items.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 8),
                _CategoryBar(
                  categories: categories,
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                ),
                const Expanded(child: Center(child: Text('Henüz ilan yok.'))),
              ],
            );
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
              const SizedBox(height: 10),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final x = filtered[i];
                    final cover = x.photoUrls.isNotEmpty ? x.photoUrls.first : null;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        // ✅ SON BAKTIKLARIM -> can_dostum
                        await UserActiveService.instance.addRecent(
                          module: 'can_dostum',
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
                            builder: (_) => CanDostumDetayPage(ilan: x),
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
                            child: const Icon(Icons.pets_outlined),
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