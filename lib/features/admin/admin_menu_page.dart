import 'package:flutter/material.dart';

import 'admin_orders_page.dart';
import 'admin_reports_page.dart';
import 'admin_duyuru_reklam_page.dart';

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Siparişler',
            subtitle: 'Market siparişlerini yönet',
            onTap: () => _go(context, const AdminOrdersPage()),
          ),
          _AdminTile(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Şikayetler',
            subtitle: 'Şikayet edilen ilanları incele',
            onTap: () => _go(context, const AdminReportsPage()),
          ),
          _AdminTile(
            icon: Icons.campaign_outlined,
            title: 'Reklam / Duyuru',
            subtitle: 'Ana sayfa duyuru ve reklamlarını yönet',
            onTap: () => _go(context, const AdminDuyuruReklamPage()),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}