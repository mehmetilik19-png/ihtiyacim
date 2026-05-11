import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'online_lobby_page.dart';
import 'online_room_service.dart';

class OnlinePublicRoomsPage extends StatefulWidget {
  OnlinePublicRoomsPage({super.key});

  @override
  State<OnlinePublicRoomsPage> createState() => _OnlinePublicRoomsPageState();
}

class _OnlinePublicRoomsPageState extends State<OnlinePublicRoomsPage> {
  final OnlineRoomService _service = OnlineRoomService();

  int _playersCount(dynamic playersVal) {
    if (playersVal is Map) return playersVal.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Açık Odalar')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('online/rooms').onValue,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.snapshot.value;
          if (data is! Map) {
            return const Center(child: Text('Açık oda yok'));
          }

          // lobby olanları filtrele
          final rooms = <Map<String, dynamic>>[];
          data.forEach((key, value) {
            if (value is Map) {
              final m = Map<String, dynamic>.from(value as Map);
              final status = (m['status'] ?? '').toString();
              if (status == 'lobby') {
                rooms.add(m);
              }
            }
          });

          // createdAt desc
          rooms.sort((a, b) {
            final aa = (a['createdAt'] as int?) ?? 0;
            final bb = (b['createdAt'] as int?) ?? 0;
            return bb.compareTo(aa);
          });

          if (rooms.isEmpty) {
            return const Center(child: Text('Açık oda yok'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = rooms[i];
              final code = (r['code'] ?? '').toString();
              final maxPlayers = (r['maxPlayers'] as int?) ?? 2;
              final players = _playersCount(r['players']);

              return Card(
                child: ListTile(
                  title: Text('Oda: $code'),
                  subtitle: Text('Oyuncular: $players / $maxPlayers'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _service.joinRoom(code);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnlineLobbyPage(code: code),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Katılınamadı: $e')),
                        );
                      }
                    },
                    child: const Text('Katıl'),
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