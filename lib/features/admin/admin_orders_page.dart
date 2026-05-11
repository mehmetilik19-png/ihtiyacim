import 'package:flutter/material.dart';

import '../orders/order_detail_page.dart';
import '../orders/order_model.dart';
import '../orders/order_repository.dart';
import 'admin_duyuru_reklam_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final repo = OrderRepository();

  OrderStatus? _filter;

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

      case OrderStatus.returnRequested:
        return 'İade talebi';

      case OrderStatus.returnApproved:
        return 'İade onaylandı';

      case OrderStatus.returnRejected:
        return 'İade reddedildi';

      case OrderStatus.returnShipping:
        return 'İade kargoda';

      case OrderStatus.returnCompleted:
        return 'İade tamamlandı';

      case OrderStatus.archived:
        return 'Arşivlendi';

      case OrderStatus.cancelled:
        return 'İptal edildi';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.created:
        return const Color(0xFFFFB300);

      case OrderStatus.preparing:
        return const Color(0xFF2196F3);

      case OrderStatus.shipped:
        return const Color(0xFF7E57C2);

      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);

      case OrderStatus.returnRequested:
        return const Color(0xFFFF9800);

      case OrderStatus.returnApproved:
        return const Color(0xFF009688);

      case OrderStatus.returnRejected:
        return const Color(0xFFD32F2F);

      case OrderStatus.returnShipping:
        return const Color(0xFF5E35B1);

      case OrderStatus.returnCompleted:
        return const Color(0xFF43A047);

      case OrderStatus.archived:
        return const Color(0xFF607D8B);

      case OrderStatus.cancelled:
        return const Color(0xFFD32F2F);
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.created:
        return Icons.fiber_new_rounded;

      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;

      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;

      case OrderStatus.delivered:
        return Icons.check_circle_outline;

      case OrderStatus.returnRequested:
        return Icons.assignment_return_outlined;

      case OrderStatus.returnApproved:
        return Icons.done_all_rounded;

      case OrderStatus.returnRejected:
        return Icons.close_rounded;

      case OrderStatus.returnShipping:
        return Icons.local_shipping_rounded;

      case OrderStatus.returnCompleted:
        return Icons.task_alt_rounded;

      case OrderStatus.archived:
        return Icons.archive_outlined;

      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Future<void> _setPreparing(OrderModel o) async {
    await repo.adminSetPreparing(o.orderId, o.buyerId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hazırlanıyor ✅'),
      ),
    );
  }

  Future<void> _setDelivered(OrderModel o) async {
    await repo.adminSetDelivered(o.orderId, o.buyerId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teslim edildi ✅'),
      ),
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
                labelText: 'Kargo şirketi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: trackingC,
              decoration: const InputDecoration(
                labelText: 'Takip numarası',
                border: OutlineInputBorder(),
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
        const SnackBar(
          content: Text('Takip numarası gerekli'),
        ),
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
      const SnackBar(
        content: Text('Kargoya verildi ✅'),
      ),
    );
  }

  List<OrderModel> _filteredOrders(List<OrderModel> all) {
    if (_filter == null) return all;

    return all.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Admin • Siparişler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDuyuruReklamPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: repo.watchAllOrders(),
        builder: (context, snap) {
          final allOrders = snap.data ?? [];

          final orders = _filteredOrders(allOrders);

          if (orders.isEmpty) {
            return const Center(
              child: Text('Sipariş yok'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];

              final color = _statusColor(o.status);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withOpacity(0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusIcon(o.status),
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusText(o.status),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${o.grandTotal.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailPage(order: o),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${o.orderId}\n${o.buyerEmail}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (o.status == OrderStatus.created)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _setPreparing(o),
                          child: const Text('Hazırlanıyor Yap'),
                        ),
                      ),

                    if (o.status == OrderStatus.preparing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _setShipped(o),
                          child: const Text('Kargoya Ver'),
                        ),
                      ),

                    if (o.status == OrderStatus.shipped)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _setDelivered(o),
                          child: const Text('Teslim Edildi Yap'),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}