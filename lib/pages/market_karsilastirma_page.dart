import 'package:flutter/material.dart';

class MarketKarsilastirmaPage extends StatelessWidget {
  const MarketKarsilastirmaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Karşılaştırma'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🛒 ikon hissi
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 20),

                Text(
                  'Yakında',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Market karşılaştırma; aynı ürünleri farklı marketlerde '
                      'tek tek dolaşmadan senin için karşılaştırır.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 14),

                Text(
                  'A markette sepet bu kadar,\n'
                      'B markette toplam şu kadar…\n'
                      'Hangisi gerçekten daha mantıklı, net şekilde görürsün.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'İstersen evine kadar getiriyoruz,\n'
                            'istersen siparişini hazırlıyoruz;\n'
                            'sen gelene kadar hazır oluyor.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Uygulama yeni olduğu için bu özellik şu an '
                      'test aşamasındadır ve yakında aktif olacaktır.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 26),

                Text(
                  'Sen ne alacağını düşün,\n'
                      'biz nereden almanın daha mantıklı olduğunu söyleyelim.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}