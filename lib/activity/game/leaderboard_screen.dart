// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhoapp/activity/game/services/score_service.dart';

import 'models/game_score.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScoreService _scoreService = ScoreService();
  String _selectedFilter = 'all';

  final Map<String, String> _gameNames = {
    'memory_match': 'Lật Hình',
    'proverb_quiz': 'Ca Dao',
    'sound_guess': 'Âm Thanh',
  };

  @override
  void initState() {
    super.initState();
    _scoreService.loadScores();
  }

  List<GameScore> _getFilteredScores() {
    if (_selectedFilter == 'all') {
      return _scoreService.getTopScores(limit: 20);
    }
    return _scoreService.getScoresByGame(_selectedFilter)
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  @override
  Widget build(BuildContext context) {
    final scores = _getFilteredScores();
    final stats = _scoreService.getGameStats();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bảng Xếp Hạng',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Header
            Container(
              margin: const EdgeInsets.all(20),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Tổng Trận',
                    _scoreService.getTotalGamesPlayed().toString(),
                    Icons.games,
                  ),
                  Container(width: 2, height: 40, color: Colors.white30),
                  _buildStatItem(
                    'Cao Nhất',
                    scores.isNotEmpty ? scores.first.score.toString() : '0',
                    Icons.emoji_events,
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'Tất Cả', stats.values.fold(0, (a, b) => a + b)),
                  _buildFilterChip('memory_match', 'Lật Hình', stats['memory_match'] ?? 0),
                  _buildFilterChip('proverb_quiz', 'Ca Dao', stats['proverb_quiz'] ?? 0),
                  _buildFilterChip('sound_guess', 'Âm Thanh', stats['sound_guess'] ?? 0),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Leaderboard List
            Expanded(
              child: scores.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chưa có điểm số nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hãy chơi game để ghi điểm!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final score = scores[index];
                  final rank = index + 1;

                  return _buildScoreCard(score, rank);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF2E7D32),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF4CAF50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
      ),
    );
  }

  Widget _buildScoreCard(GameScore score, int rank) {
    Color getRankColor() {
      if (rank == 1) return Colors.amber;
      if (rank == 2) return Colors.grey[400]!;
      if (rank == 3) return Colors.orange[300]!;
      return const Color(0xFF4CAF50);
    }

    IconData getRankIcon() {
      if (rank <= 3) return Icons.emoji_events;
      return Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: rank <= 3 ? getRankColor().withOpacity(0.5) : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          if (rank <= 3)
            BoxShadow(
              color: getRankColor().withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: getRankColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  getRankIcon(),
                  color: getRankColor(),
                  size: rank <= 3 ? 24 : 20,
                ),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: getRankColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // Game Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _gameNames[score.gameType] ?? score.gameType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(score.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: getRankColor(),
                ),
              ),
              Text(
                'điểm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}