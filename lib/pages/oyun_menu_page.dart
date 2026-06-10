import 'package:flutter/material.dart';
import 'package:ihtiyacim/game/quiz_engine.dart';
import 'package:ihtiyacim/game/quiz_progress_repo.dart' as quiz_progress_repo;
import 'package:ihtiyacim/game/quiz_repo.dart';

import 'oyun_page.dart';
import 'package:ihtiyacim/pages/online/online_lobby_page.dart';
import 'package:ihtiyacim/pages/online/online_public_rooms_page.dart';

class OyunMenuPage extends StatefulWidget {
  const OyunMenuPage({super.key});

  @override
  State<OyunMenuPage> createState() => _OyunMenuPageState();
}

class _OyunMenuPageState extends State<OyunMenuPage> {
  late final QuizEngine engine;
  bool _loading = true;

  static const Color bgTop = Color(0xFF050B18);
  static const Color bgMiddle = Color(0xFF071D35);
  static const Color bgBottom = Color(0xFF082B4F);

  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color purple = Color(0xFF8B5CFF);
  static const Color orange = Color(0xFFFFB84D);
  static const Color green = Color(0xFF35F2A2);

  @override
  void initState() {
    super.initState();

    engine = QuizEngine(
      QuizRepo(),
      quiz_progress_repo.QuizProgressRepo(),
    );

    _load();
  }

  Future<void> _load() async {
    await engine.init();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _openGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OyunPage(),
      ),
    );

    await _load();
  }

  void _openOnlineLobby() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OnlineLobbyPage(code: ''),
      ),
    );
  }

  void _openPublicRooms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlinePublicRoomsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgTop,
              bgMiddle,
              bgBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(color: neonBlue),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 26),
                const Text(
                  'Oyun Merkezi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tek başına ilerle veya arkadaşlarınla aynı soruda kapış.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLeagueCard(),
                const SizedBox(height: 22),
                _buildGameModeButton(
                  icon: Icons.bolt_rounded,
                  title: 'Tek Kişilik Oyna',
                  subtitle: 'Lig puanı kas, rekorunu yükselt',
                  color1: electricBlue,
                  color2: neonBlue,
                  onTap: _openGame,
                ),
                const SizedBox(height: 14),
                _buildGameModeButton(
                  icon: Icons.add_rounded,
                  title: 'Oda Oluştur',
                  subtitle: 'Kod oluştur, arkadaşlarını davet et',
                  color1: purple,
                  color2: neonBlue,
                  onTap: _openOnlineLobby,
                ),
                const SizedBox(height: 14),
                _buildGameModeButton(
                  icon: Icons.meeting_room_rounded,
                  title: 'Odaya Katıl',
                  subtitle: 'Kod gir ve aynı soruda yarış',
                  color1: green,
                  color2: neonBlue,
                  onTap: _openOnlineLobby,
                ),
                const SizedBox(height: 14),
                _buildGameModeButton(
                  icon: Icons.public_rounded,
                  title: 'Açık Odalar',
                  subtitle: 'Herkese açık odalara hızlı katıl',
                  color1: orange,
                  color2: purple,
                  onTap: _openPublicRooms,
                ),
                const SizedBox(height: 22),
                _buildSimpleInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: neonBlue.withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: neonBlue.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard() {
    final nextLeague = engine.nextLeagueName;
    final needed = engine.questionsToNextLeague;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.055),
          ],
        ),
        border: Border.all(
          color: neonBlue.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      engine.leagueColor.withOpacity(0.95),
                      neonBlue.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: engine.leagueColor.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      engine.currentLeagueName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '#${engine.currentRank}/50  •  ${engine.seasonCorrect} Doğru',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: engine.leagueProgress,
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation(engine.leagueColor),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            needed <= 0
                ? 'Üst lige çıkmaya hazırsın: $nextLeague'
                : '$nextLeague için $needed doğru cevap daha gerekiyor',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.075),
          border: Border.all(
            color: color1.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                    color: color1.withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.52),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: neonBlue.withOpacity(0.08),
        border: Border.all(
          color: neonBlue.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.flash_on_rounded,
            color: neonBlue,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Online modda aynı soru herkese gelir. İlk doğru cevaplayan oyuncu puanı alır.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}