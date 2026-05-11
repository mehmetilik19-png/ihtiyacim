import 'package:flutter/material.dart';
import 'order_model.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Detayı')),
      body: ListView(
        children: [
          ListTile(title: Text('Email'), subtitle: Text(order.buyerEmail)),
          ListTile(title: Text('Toplam'), subtitle: Text(order.grandTotal.toString())),
        ],
      ),
    );
  }
}