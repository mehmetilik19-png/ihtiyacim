import 'package:flutter/material.dart';

import 'package:ihtiyacim/data/engelsiz_is_catalog.dart';
import 'package:ihtiyacim/models/engelsiz_is_model.dart';
import 'package:ihtiyacim/services/engelsiz_is_rtdb_service.dart';
import 'package:ihtiyacim/pages/engelsiz_is_detay_page.dart';
import 'package:ihtiyacim/pages/engelsiz_is_ilan_ekle_page.dart';

class EngelsizIsPage extends StatefulWidget {
  const EngelsizIsPage({super.key});

  @override
  State<EngelsizIsPage> createState() => _EngelsizIsPageState();
}

class _EngelsizIsPageState extends State<EngelsizIsPage> {
  final _service = EngelsizIsRtdbService();

  // üst filtre: tür
  String selectedType = 'hepsi'; // hepsi | is_arayan | isci_arayan

  // sol kategori
  String selectedCategory = 'Tümü';

  // şehir dropdown
  String selectedCity = 'Tümü';

  // arama
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  bool pass(EngelsizIsModel x) {
    // type
    if (selectedType != 'hepsi' && x.type != selectedType) return false;

    // category
    if (selectedCategory != 'Tümü' && x.category != selectedCategory) return false;

    // city
    if (selectedCity != 'Tümü' && x.city != selectedCity) return false;

    // search (meslek/title içinde)
    final q = _searchC.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final t = x.title.toLowerCase();
      final c = x.category.toLowerCase();
      if (!t.contains(q) && !c.contains(q)) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final leftCats = EngelsizIsCatalog.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engelsiz İş'),
        actions: [
          IconButton(
            tooltip: 'İlan Ekle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EngelsizIsIlanEklePage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // ÜST: tür chipleri + arama + il
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: selectedType == 'hepsi',
                      onSelected: (_) => setState(() => selectedType = 'hepsi'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('İş Arayanlar'),
                      selected: selectedType == 'is_arayan',
                      onSelected: (_) => setState(() => selectedType = 'is_arayan'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('İşçi Arayanlar'),
                      selected: selectedType == 'isci_arayan',
                      onSelected: (_) => setState(() => selectedType = 'isci_arayan'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchC,
                        decoration: const InputDecoration(
                          hintText: 'Meslek / pozisyon ara...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'İl',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                          ...EngelsizIsCatalog.cities.map(
                                (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: (v) => setState(() => selectedCity = v ?? 'Tümü'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // SOL kategori
                SizedBox(
                  width: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 10, right: 6, top: 8),
                    itemCount: leftCats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final v = leftCats[i];
                      final selected = selectedCategory == v;
                      return InkWell(
                        onTap: () => setState(() => selectedCategory = v),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selected
                                ? Theme.of(context).colorScheme.primary.withOpacity(.12)
                                : null,
                          ),
                          child: Text(
                            v,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // SAĞ liste
                Expanded(
                  child: StreamBuilder<List<EngelsizIsModel>>(
                    stream: _service.streamAll(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Hata: ${snap.error}'));
                      }

                      final all = snap.data ?? [];
                      final items = all.where(pass).toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      if (items.isEmpty) {
                        return const Center(child: Text('İlan bulunamadı.'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(6, 8, 12, 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final x = items[i];
                          final typeText = x.type == 'is_arayan' ? 'İş Arayan' : 'İşçi Arayan';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              title: Text(
                                x.title,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: Text('$typeText • ${x.category} • ${x.city}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EngelsizIsDetayPage(item: x),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}