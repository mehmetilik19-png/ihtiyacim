import 'package:flutter/material.dart';

import '../orders/order_model.dart';
import '../orders/order_repository.dart';
import '../orders/order_detail_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final repo = OrderRepository();

  String _statusText(OrderStatus s) {
    switch (s) {
      case OrderStatus.created:
        return 'Sipariş alındı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.shipped:
        return 'Kargoya verildi';
      case OrderStatus.delivered:
        return 'Teslim edildi';
      case OrderStatus.cancelled:
        return 'İptal edildi';
    }
  }

  Future<void> _setPreparing(OrderModel o) async {
    await repo.adminSetPreparing(o.orderId, o.buyerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Durum güncellendi: Hazırlanıyor ✅')),
    );
  }

  Future<void> _setDelivered(OrderModel o) async {
    await repo.adminSetDelivered(o.orderId, o.buyerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Durum güncellendi: Teslim edildi ✅')),
    );
  }

  Future<void> _setShipped(OrderModel o) async {
    final trackingC = TextEditingController();
    final companyC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kargoya Ver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyC,
              decoration: const InputDecoration(
                labelText: 'Kargo şirketi (opsiyonel)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: trackingC,
              decoration: const InputDecoration(
                labelText: 'Takip no (zorunlu)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final trackingNo = trackingC.text.trim();
    final company = companyC.text.trim();

    if (trackingNo.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takip no zorunlu.')),
      );
      return;
    }

    await repo.adminSetShipped(
      orderId: o.orderId,
      buyerId: o.buyerId,
      trackingNo: trackingNo,
      company: company.isEmpty ? null : company,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Durum güncellendi: Kargoya verildi ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Siparişler')),
      body: StreamBuilder<List<OrderModel>>(
        stream: repo.watchAllOrders(),
        builder: (context, snap) {
          final orders = snap.data ?? const <OrderModel>[];

          if (snap.connectionState == ConnectionState.waiting && orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orders.isEmpty) {
            return const Center(child: Text('Sipariş yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = orders[i];

              return Card(
                elevation: 0.4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '#${o.orderId}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${o.buyerEmail}\n${_statusText(o.status)} • ${o.grandTotal.toStringAsFixed(0)} TL',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailPage(order: o),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _setPreparing(o),
                            child: const Text('Hazırlanıyor'),
                          ),
                          OutlinedButton(
                            onPressed: () => _setShipped(o),
                            child: const Text('Kargoya verildi'),
                          ),
                          OutlinedButton(
                            onPressed: () => _setDelivered(o),
                            child: const Text('Teslim edildi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 