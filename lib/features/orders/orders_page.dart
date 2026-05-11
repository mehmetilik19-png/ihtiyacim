import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'order_model.dart';
import 'order_repository.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  String _statusText(OrderStatus s) {
    switch (s) {
      case OrderStatus.created:
        return 'created';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      default:
        return s.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapılmamış.')),
      );
    }

    final repo = OrderRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: StreamBuilder<List<String>>(
        stream: repo.watchUserOrderIds(u.uid),
        builder: (context, snap) {
          final ids = snap.data ?? const <String>[];

          if (snap.connectionState == ConnectionState.waiting && ids.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ids.isEmpty) {
            return const Center(
              child: Text(
                'Henüz sipariş yok.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final orderId = ids[i];

              return StreamBuilder<OrderModel?>(
                stream: repo.watchOrder(orderId),
                builder: (context, os) {
                  final o = os.data;
                  if (o == null) {
                    return Card(
                      child: ListTile(
                        title: Text('#$orderId'),
                        subtitle:
                        const Text('Sipariş yüklenemedi / silinmiş olabilir'),
                      ),
                    );
                  }

                  return Card(
                    elevation: 0.4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(
                        '#${o.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${_statusText(o.status)} • ${o.items.length} ürün • ${o.grandTotal.toStringAsFixed(0)} TL',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // ✅ ÖNEMLİ: Senin OrderDetailPage "order:" istiyor.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailPage(order: o),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}