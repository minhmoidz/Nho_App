// lib/screens/memory_match_game.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gioapp/trochoi/services/score_service.dart';

import 'models/game_score.dart';
class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({Key? key}) : super(key: key);

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  final ScoreService _scoreService = ScoreService();

  List<String> _cards = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstCard;
  int _score = 0;
  int _moves = 0;
  bool _isChecking = false;

  final List<String> _cardSymbols = [
    '🌸', '🌺', '🌻', '🌷', '🌹', '🏵️',
    '🍎', '🍊', '🍋', '🍌', '🍉', '🍇',
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Create pairs
    _cards = [..._cardSymbols.take(8), ..._cardSymbols.take(8)];
    _cards.shuffle();
    _revealed = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _firstCard = null;
    _score = 0;
    _moves = 0;
    _isChecking = false;
  }

  void _onCardTap(int index) {
    if (_isChecking || _revealed[index] || _matched[index]) return;

    setState(() {
      _revealed[index] = true;

      if (_firstCard == null) {
        _firstCard = index;
      } else {
        _moves++;
        _isChecking = true;

        final firstIndex = _firstCard!;
        if (_cards[firstIndex] == _cards[index]) {
          // Match found
          _matched[firstIndex] = true;
          _matched[index] = true;
          _score += 10;
          _firstCard = null;
          _isChecking = false;

          // Check if game completed
          if (_matched.every((m) => m)) {
            _showCompletionDialog();
          }
        } else {
          // No match
          Timer(const Duration(milliseconds: 800), () {
            setState(() {
              _revealed[firstIndex] = false;
              _revealed[index] = false;
              _firstCard = null;
              _isChecking = false;
            });
          });
        }
      }
    });
  }

  void _showCompletionDialog() {
    _scoreService.saveScore(GameScore(
      gameType: 'memory_match',
      score: _score,
      date: DateTime.now(),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Xuất Sắc!',
          style: TextStyle(color: Color(0xFF4CAF50), fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã hoàn thành trò chơi!',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score điểm',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    'Số nước: $_moves',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Về trang chủ', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initGame());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Chơi lại', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Lật Hình Tìm Cặp',
          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Panel
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreItem('Điểm', _score.toString(), Icons.star),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildScoreItem('Nước đi', _moves.toString(), Icons.touch_app),
                ],
              ),
            ),

            // Game Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _matched[index]
                              ? Colors.green[100]
                              : _revealed[index]
                              ? Colors.white
                              : const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _revealed[index] || _matched[index]
                                ? _cards[index]
                                : '?',
                            style: TextStyle(
                              fontSize: 32,
                              color: _revealed[index] || _matched[index]
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Reset Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _initGame()),
                icon: const Icon(Icons.refresh, size: 24),
                label: const Text('Chơi lại', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }
}