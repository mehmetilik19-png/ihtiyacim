import 'package:flutter/material.dart';

class MarketKarsilastirmaPage extends StatelessWidget {
  const MarketKarsilastirmaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {
        'name': 'Süt 1L',
        'a101': 32,
        'bim': 31,
        'sok': 33,
        'migros': 35,
      },
      {
        'name': 'Yumurta 30lu',
        'a101': 129,
        'bim': 124,
        'sok': 132,
        'migros': 139,
      },
      {
        'name': 'Ayçiçek Yağı 5L',
        'a101': 289,
        'bim': 279,
        'sok': 295,
        'migros': 309,
      },
      {
        'name': 'Makarna',
        'a101': 24,
        'bim': 22,
        'sok': 23,
        'migros': 27,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Karşılaştırma'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.green.withOpacity(.08),
              border: Border.all(
                color: Colors.green.withOpacity(.2),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 52,
                  color: Colors.green,
                ),
                SizedBox(height: 12),
                Text(
                  'Market Fiyat Karşılaştırma',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Aynı ürünün farklı marketlerdeki yaklaşık fiyatlarını kolayca karşılaştır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ...products.map((item) {
            final prices = [
              item['a101'] as int,
              item['bim'] as int,
              item['sok'] as int,
              item['migros'] as int,
            ];

            final minPrice = prices.reduce((a, b) => a < b ? a : b);

            String bestMarket = '';

            if (minPrice == item['a101']) {
              bestMarket = 'A101';
            } else if (minPrice == item['bim']) {
              bestMarket = 'BİM';
            } else if (minPrice == item['sok']) {
              bestMarket = 'ŞOK';
            } else {
              bestMarket = 'Migros';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withOpacity(.06),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    color: Colors.black.withOpacity(.04),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _priceRow('A101', item['a101'], minPrice),
                  _priceRow('BİM', item['bim'], minPrice),
                  _priceRow('ŞOK', item['sok'], minPrice),
                  _priceRow('Migros', item['migros'], minPrice),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withOpacity(.08),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'En uygun fiyat: $bestMarket',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          const Text(
            'Fiyatlar örnek/demo amaçlı gösterilmektedir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _priceRow(
    String market,
    dynamic price,
    int minPrice,
  ) {
    final bool isBest = price == minPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              market,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isBest
                  ? Colors.green.withOpacity(.12)
                  : Colors.grey.withOpacity(.08),
            ),
            child: Text(
              '$price TL',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isBest ? Colors.green : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
