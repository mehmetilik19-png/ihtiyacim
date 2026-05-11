import 'package:flutter/material.dart';
import '../models/engelsiz_is_model.dart';

class EngelsizIsDetayPage extends StatelessWidget {
  const EngelsizIsDetayPage({super.key, required this.item});
  final EngelsizIsModel item;

  @override
  Widget build(BuildContext context) {
    final typeText = item.type == 'is_arayan' ? 'İş Arayan' : 'İşçi Arayan';

    return Scaffold(
      appBar: AppBar(title: const Text('Detay')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(typeText)),
              Chip(label: Text(item.category)),
              Chip(label: Text(item.city)),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.desc, style: const TextStyle(fontSize: 15, height: 1.35)),
          const SizedBox(height: 18),

          const Text('İletişim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: Text(item.contactName),
              subtitle: Text('Tel: ${item.phone}\nWP: ${item.whatsapp.isEmpty ? '-' : item.whatsapp}'),
            ),
          ),
        ],
      ),
    );
  }
}