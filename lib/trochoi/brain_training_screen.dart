// lib/screens/brain_training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gioapp/trochoi/services/score_service.dart';
import 'memory_match_game.dart';
import 'proverb_quiz_game.dart';
import 'sound_guess_game.dart';
import 'leaderboard_screen.dart';

class BrainTrainingScreen extends StatefulWidget {
  const BrainTrainingScreen({Key? key}) : super(key: key);

  @override
  State<BrainTrainingScreen> createState() => _BrainTrainingScreenState();
}

class _BrainTrainingScreenState extends State<BrainTrainingScreen> {
  final ScoreService _scoreService = ScoreService();

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    await _scoreService.loadScores();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Rèn Luyện Trí Não',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Color(0xFF2E7D32), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giữ Trí Não Minh Mẫn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Chơi ${_scoreService.getTotalGamesPlayed()} trận',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Games Section
              const Text(
                'Các Trò Chơi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),

              // Game Cards
              _buildGameCard(
                context,
                title: 'Lật Hình Tìm Cặp',
                description: 'Rèn luyện trí nhớ với trò chơi lật hình cổ điển',
                icon: Icons.grid_on,
                color: const Color(0xFF4CAF50),
                bestScore: _scoreService.getBestScore('memory_match'),
                onTap: () => _navigateToGame(context, const MemoryMatchGame()),
              ),
              const SizedBox(height: 15),

              _buildGameCard(
                context,
                title: 'Đố Vui Ca Dao',
                description: 'Nhớ lại những câu ca dao, tục ngữ quen thuộc',
                icon: Icons.menu_book,
                color: const Color(0xFF66BB6A),
                bestScore: _scoreService.getBestScore('proverb_quiz'),
                onTap: () => _navigateToGame(context, const ProverbQuizGame()),
              ),
              const SizedBox(height: 15),

              _buildGameCard(
                context,
                title: 'Nghe Âm Đoán Vật',
                description: 'Đoán đồ vật qua tiếng kêu đặc trưng',
                icon: Icons.volume_up,
                color: const Color(0xFF81C784),
                bestScore: _scoreService.getBestScore('sound_guess'),
                onTap: () => _navigateToGame(context, const SoundGuessGame()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required int bestScore,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 35, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    if (bestScore > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 5),
                          Text(
                            'Kỷ lục: $bestScore điểm',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Widget game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => game),
    );
    _loadScores();
  }
}