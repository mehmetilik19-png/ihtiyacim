import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ustam_model.dart';
import '../constants/cities.dart';
import 'ustam_detay_page.dart';
import 'ustam_ilan_ekle_page.dart';

class UstamPage extends StatefulWidget {
  const UstamPage({super.key});

  @override
  State<UstamPage> createState() => _UstamPageState();
}

class _UstamPageState extends State<UstamPage> {
  final _dbRef = FirebaseDatabase.instance.ref('ustam/items');

  String selectedCity = 'Tümü';
  String selectedJob = 'Tümü';

  static const jobs = [
    'Tümü',
    'Boyacı',
    'Elektrik',
    'Su Tesisatı',
    'Marangoz',
    'Diğer',
  ];

  Stream<List<UstamModel>> _stream() {
    return _dbRef.onValue.map((e) {
      if (e.snapshot.value == null) return [];
      final map = Map<dynamic, dynamic>.from(e.snapshot.value as Map);
      return map.entries
          .map((e) => UstamModel.fromMap(e.key, Map.from(e.value)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  bool _match(UstamModel u) {
    final cityOk = selectedCity == 'Tümü' ||
        UstamModel.norm(u.city) == UstamModel.norm(selectedCity);

    final jobOk = selectedJob == 'Tümü' ||
        UstamModel.norm(u.job) == UstamModel.norm(selectedJob);

    return cityOk && jobOk;
  }

  @override
  Widget build(BuildContext context) {
    // Eğer eski veride city boşsa dropdown kırılmasın
    if (!Cities.all.contains(selectedCity)) selectedCity = 'Tümü';
    if (!jobs.contains(selectedJob)) selectedJob = 'Tümü';

    return Scaffold(
      appBar: AppBar(title: const Text('Ustam')),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UstamIlanEklePage()),
          );
        },
      ),

      body: Column(
        children: [
          // ✅ İL DROPDOWN (81 il)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedCity,
              items: Cities.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCity = v ?? 'Tümü'),
              decoration: const InputDecoration(labelText: 'İl'),
            ),
          ),

          // ✅ MESLEK CHIP BAR
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final j = jobs[i];
                return ChoiceChip(
                  label: Text(j),
                  selected: selectedJob == j,
                  onSelected: (_) => setState(() => selectedJob = j),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ✅ LISTE
          Expanded(
            child: StreamBuilder<List<UstamModel>>(
              stream: _stream(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = s.data!.where(_match).toList();
                if (list.isEmpty) return const Center(child: Text('İlan yok'));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return ListTile(
                      leading: u.photoUrls.isEmpty
                          ? const Icon(Icons.person)
                          : Image.network(
                        u.photoUrls.first,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
                      title: Text(u.title),
                      subtitle: Text('${u.job} • ${u.city}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UstamDetayPage(ustam: u)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}