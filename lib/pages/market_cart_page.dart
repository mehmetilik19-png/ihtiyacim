import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'payment_webview_page.dart';

class MarketCartPage extends StatefulWidget {
  const MarketCartPage({super.key});

  @override
  State<MarketCartPage> createState() => _MarketCartPageState();
}

class _MarketCartPageState extends State<MarketCartPage> {
  // ÖRNEK SEPET VERİSİ (senin projende zaten cart listesi vardır)
  // İstersen bunu kendi cart modelinle değiştir.
  final List<_CartItem> _items = [
    _CartItem(name: "hhjj", price: 1.0, qty: 1),
  ];

  double get total =>
      _items.fold(0, (sum, item) => sum + (item.price * item.qty));

  void _increaseQty(int index) {
    setState(() => _items[index] = _items[index].copyWith(qty: _items[index].qty + 1));
  }

  void _decreaseQty(int index) {
    if (_items[index].qty <= 1) return;
    setState(() => _items[index] = _items[index].copyWith(qty: _items[index].qty - 1));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _goToPayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sepet boş")),
      );
      return;
    }

    try {
      // İstersen burada sepetteki ürünleri servera yollayacak hale de getiririz.
      final paymentUrl = await PaymentService.createPayment();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewPage(url: paymentUrl),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sepet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _items.isEmpty
                ? null
                : () => setState(() => _items.clear()),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("Sepette ürün yok"))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Birim: ${item.price.toStringAsFixed(2)} TL"),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _decreaseQty(index),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "${item.qty}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () => _increaseQty(index),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${(item.price * item.qty).toStringAsFixed(2)} TL",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: const Text(
                          "sil",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ALT BAR (TOPLAM + ÖDEME)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("Toplam:", style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text(
                        "${total.toStringAsFixed(2)} TL",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _goToPayment,
                      child: const Text("Ödemeye Geç"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Basit cart modeli (örnek)
class _CartItem {
  final String name;
  final double price;
  final int qty;

  const _CartItem({
    required this.name,
    required this.price,
    required this.qty,
  });

  _CartItem copyWith({String? name, double? price, int? qty}) {
    return _CartItem(
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
    );
  }
}