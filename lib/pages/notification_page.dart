import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool notificationsEnabled = true;

  final List<Map<String, String>> notifications = [
    {
      'title': 'Test',
      'body': 'İhtiyacım bildirimi geldi',
      'time': 'Şimdi',
    },
  ];

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  void _openDetail(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item['title'] ?? 'Bildirim'),
        content: Text(item['body'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFFFFF7FF),
        actions: [
          IconButton(
            tooltip: notificationsEnabled
                ? 'Bildirimleri kapat'
                : 'Bildirimleri aç',
            onPressed: _toggleNotifications,
            icon: Icon(
              notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          'Yeni bildirim yok',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Dismissible(
            key: ValueKey('${item['title']}_$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteNotification(index),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: Card(
              child: ListTile(
                onTap: () => _openDetail(item),
                leading: const Icon(Icons.notifications),
                title: Text(item['title'] ?? ''),
                subtitle: Text(item['body'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'detail') {
                      _openDetail(item);
                    } else if (value == 'delete') {
                      _deleteNotification(index);
                    } else if (value == 'toggle') {
                      _toggleNotifications();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Text('Detaya git'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        notificationsEnabled
                            ? 'Bildirimleri kapat'
                            : 'Bildirimleri aç',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}