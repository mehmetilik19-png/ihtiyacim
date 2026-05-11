import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'online_room_service.dart';

class OnlineLobbyPage extends StatefulWidget {
  final String code;
  const OnlineLobbyPage({super.key, required this.code});

  @override
  State<OnlineLobbyPage> createState() => _OnlineLobbyPageState();
}

class _OnlineLobbyPageState extends State<OnlineLobbyPage> {
  final OnlineRoomService _service = OnlineRoomService();
  bool _busy = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('online/rooms/${widget.code}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Oda: ${widget.code}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _busy
                ? null
                : () async {
              setState(() => _busy = true);
              try {
                await _service.leaveRoom(widget.code);
                if (!mounted) return;
                Navigator.pop(context);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final val = snap.data!.snapshot.value;
          if (val is! Map) {
            return const Center(child: Text('Oda bulunamadı'));
          }

          final m = Map<dynamic, dynamic>.from(val);
          final status = (m['status'] ?? 'lobby').toString();
          final hostUid = (m['hostUid'] ?? '').toString();
          final maxPlayers = (m['maxPlayers'] as int?) ?? 2;

          final playersMap = (m['players'] is Map)
              ? Map<dynamic, dynamic>.from(m['players'] as Map)
              : <dynamic, dynamic>{};

          final isHost = _uid != null && _uid == hostUid;

          final players = playersMap.values
              .whereType<Map>()
              .map((e) => Map<dynamic, dynamic>.from(e))
              .toList();

          players.sort((a, b) {
            final aa = (a['joinedAt'] as int?) ?? 0;
            final bb = (b['joinedAt'] as int?) ?? 0;
            return aa.compareTo(bb);
          });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  status == 'lobby' ? 'Bekleme Odası' : 'Oyun Başladı',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Oyuncular: ${players.length} / $maxPlayers'),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = players[i];
                      final name = (p['name'] ?? 'Oyuncu').toString();
                      final score = (p['score'] as int?) ?? 0;
                      final uid = (p['uid'] ?? '').toString();
                      final badge = (uid == hostUid) ? ' (Host)' : '';

                      return ListTile(
                        title: Text('$name$badge'),
                        trailing: Text('Skor: $score'),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                if (status == 'lobby' && isHost)
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                      setState(() => _busy = true);
                      try {
                        await _service.startGame(widget.code);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Oyun başlatıldı!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Başlatılamadı: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
                    child: const Text('Oyunu Başlat'),
                  ),

                if (status != 'lobby')
                  const Text(
                    'Oyun başladı. (Online oyun ekranını sonra bağlayacağız)',
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}