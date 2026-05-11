import 'package:flutter/material.dart';
import 'package:ihtiyacim/game/services/stats_servive.dart';

class StatsBanner extends StatelessWidget {
  final StatsSnapshot snap;
  final int currentCorrect;

  const StatsBanner({
    super.key,
    required this.snap,
    required this.currentCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final max = snap.globalMaxCorrect;
    final total = snap.totalUsers;
    final rank = snap.myRank;
    final myBest = snap.myBestCorrect;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lig Durumu',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            max <= 0
                ? 'İlk rekoru sen kır'
                : '$max doğruyu geçen henüz olmadı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            max <= 0
                ? 'Oyuna başla ve lider ol.'
                : 'Lider: ${snap.globalLeaderName.isEmpty ? "Bilinmiyor" : snap.globalLeaderName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  title: 'Bu Oyun',
                  value: '$currentCorrect',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  title: 'Rekorun',
                  value: '$myBest',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  title: 'Sıralama',
                  value: '#$rank',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  title: 'Oyuncu',
                  value: '$total',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}