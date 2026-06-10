import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  DatabaseReference get _reportsRef =>
      FirebaseDatabase.instance.ref('reports');

  String _itemPath(String module, String itemId) {
    switch (module) {
      case 'can_dostum':
        return 'can_dostum/items/$itemId';
      case 'esya_paylas':
        return 'esya_paylas/items/$itemId';
      case 'gecerken_beni_de_al':
        return 'gecerken_beni_de_al/items/$itemId';
      case 'engelsiz_is':
        return 'engelsiz_is/items/$itemId';
      case 'ustam':
        return 'ustam/items/$itemId';
      default:
        return '';
    }
  }

  Future<void> _deleteReportedItem(
      BuildContext context,
      String reportId,
      Map data,
      ) async {
    final module = (data['module'] ?? '').toString();
    final itemId = (data['itemId'] ?? '').toString();

    final path = _itemPath(module, itemId);

    if (path.isEmpty || itemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan yolu bulunamadı.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İlan silinsin mi?'),
        content: const Text('Şikayet edilen ilan tamamen silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseDatabase.instance.ref(path).remove();

    await _reportsRef.child(reportId).update({
      'status': 'item_deleted',
      'resolvedAt': ServerValue.timestamp,
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İlan silindi ve şikayet kapatıldı.')),
    );
  }

  Future<void> _markResolved(String reportId) async {
    await _reportsRef.child(reportId).update({
      'status': 'resolved',
      'resolvedAt': ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikayetler'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _reportsRef.onValue,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final value = snap.data!.snapshot.value;

          if (value == null || value is! Map) {
            return const Center(
              child: Text('Henüz şikayet yok.'),
            );
          }

          final raw = Map<dynamic, dynamic>.from(value);

          final reports = raw.entries.toList()
            ..sort((a, b) {
              final am = a.value is Map
                  ? Map<dynamic, dynamic>.from(a.value)
                  : {};
              final bm = b.value is Map
                  ? Map<dynamic, dynamic>.from(b.value)
                  : {};

              final ac = int.tryParse((am['createdAt'] ?? '0').toString()) ?? 0;
              final bc = int.tryParse((bm['createdAt'] ?? '0').toString()) ?? 0;

              return bc.compareTo(ac);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final reportId = reports[i].key.toString();
              final data = reports[i].value is Map
                  ? Map<dynamic, dynamic>.from(reports[i].value)
                  : <dynamic, dynamic>{};

              final title = (data['itemTitle'] ?? 'Başlıksız').toString();
              final module = (data['module'] ?? '-').toString();
              final reason = (data['reason'] ?? '-').toString();
              final status = (data['status'] ?? 'pending').toString();
              final reporter = (data['reporterUserId'] ?? '-').toString();
              final reported = (data['reportedUserId'] ?? '-').toString();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Modül: $module'),
                      Text('Sebep: $reason'),
                      Text('Durum: $status'),
                      const SizedBox(height: 6),
                      Text(
                        'Şikayet eden: $reporter',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Şikayet edilen: $reported',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _deleteReportedItem(
                                context,
                                reportId,
                                data,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('İlanı Sil'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _markResolved(reportId),
                              icon: const Icon(Icons.check),
                              label: const Text('Çözüldü'),
                            ),
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