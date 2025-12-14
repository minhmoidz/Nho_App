// lib/screens/proverb_quiz_game.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gioapp/activity/game/services/score_service.dart';

import 'models/game_score.dart';


class ProverbQuizGame extends StatefulWidget {
  const ProverbQuizGame({Key? key}) : super(key: key);

  @override
  State<ProverbQuizGame> createState() => _ProverbQuizGameState();
}

class _ProverbQuizGameState extends State<ProverbQuizGame> {
  final ScoreService _scoreService = ScoreService();

  final List<Proverb> _proverbs = [
    Proverb(
      question: 'Có công mài sắt...',
      options: ['có ngày nên kim', 'có ngày nên vàng', 'có ngày thành công', 'có ngày giàu sang'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Kiên trì làm việc sẽ có kết quả tốt đẹp',
    ),
    Proverb(
      question: 'Ăn quả nhớ...',
      options: ['kẻ trồng cây', 'người làm vườn', 'cây ăn quả', 'thời tiết tốt'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Biết ơn người có công lao trước đây',
    ),
    Proverb(
      question: 'Một giọt máu đào...',
      options: ['hơn ao nước lã', 'quý hơn vàng', 'thắm đậm tình thân', 'chảy mãi trong tim'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Tình ruột thịt quý giá hơn những mối quan hệ bên ngoài',
    ),
    Proverb(
      question: 'Học thầy không tày...',
      options: ['học bạn', 'học trò', 'học sách', 'học đời'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Bạn bè cũng là nguồn học hỏi quý giá',
    ),
    Proverb(
      question: 'Không thầy đố mày...',
      options: ['làm nên', 'thành công', 'học giỏi', 'biết chữ'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Thầy giáo đóng vai trò quan trọng trong sự học',
    ),
    Proverb(
      question: 'Lời nói chẳng mất...',
      options: ['tiền mua', 'công sức', 'thời gian', 'sức lực'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Nói lời hay, lời tốt không tốn kém gì',
    ),
    Proverb(
      question: 'Xa mặt...',
      options: ['cách lòng', 'xa tim', 'quên ngay', 'mất tình'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Xa nhau lâu ngày dễ phai nhạt tình cảm',
    ),
    Proverb(
      question: 'Uống nước nhớ...',
      options: ['nguồn', 'suối', 'giếng', 'sông'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Biết ơn cội nguồn, tổ tiên',
    ),
    Proverb(
      question: 'Chớ thấy sóng cả...',
      options: ['mà ngã tay chèo', 'mà sợ hãi', 'mà bỏ thuyền', 'mà không chèo'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Đừng vì khó khăn mà bỏ cuộc',
    ),
    Proverb(
      question: 'Ở hiền gặp...',
      options: ['lành', 'tốt', 'may', 'phước'],
      correctAnswer: 0,
      explanation: 'Ý nghĩa: Làm người hiền lành sẽ gặp may mắn',
    ),
  ];

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  List<Proverb> _shuffledProverbs = [];

  @override
  void initState() {
    super.initState();
    _shuffledProverbs = List.from(_proverbs)..shuffle();
  }

  void _selectAnswer(int index) {
    if (_showResult) return;

    setState(() {
      _selectedAnswer = index;
      _showResult = true;

      if (index == _shuffledProverbs[_currentIndex].correctAnswer) {
        _score += 10;
      }
    });

    Timer(const Duration(seconds: 2), () {
      if (_currentIndex < _shuffledProverbs.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _showResult = false;
        });
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    _scoreService.saveScore(GameScore(
      gameType: 'proverb_quiz',
      score: _score,
      date: DateTime.now(),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎊 Hoàn Thành!',
          style: TextStyle(color: Color(0xFF66BB6A), fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã trả lời ${_score ~/ 10}/${_shuffledProverbs.length} câu đúng',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_score điểm',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66BB6A),
                ),
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
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _showResult = false;
                _shuffledProverbs.shuffle();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
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
    final currentProverb = _shuffledProverbs[_currentIndex];

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
          'Đố Vui Ca Dao',
          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1}/${_shuffledProverbs.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFF66BB6A), size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '$_score điểm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF66BB6A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _shuffledProverbs.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 40),

              // Question
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  currentProverb.question,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: currentProverb.options.length,
                  itemBuilder: (context, index) {
                    final isCorrect = index == currentProverb.correctAnswer;
                    final isSelected = _selectedAnswer == index;

                    Color getColor() {
                      if (!_showResult) return Colors.white;
                      if (isSelected && isCorrect) return Colors.green[50]!;
                      if (isSelected && !isCorrect) return Colors.red[50]!;
                      if (isCorrect) return Colors.green[50]!;
                      return Colors.white;
                    }

                    Color getBorderColor() {
                      if (!_showResult) return const Color(0xFF66BB6A);
                      if (isSelected && isCorrect) return Colors.green;
                      if (isSelected && !isCorrect) return Colors.red;
                      if (isCorrect) return Colors.green;
                      return Colors.grey[300]!;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectAnswer(index),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: getColor(),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: getBorderColor(),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentProverb.options[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_showResult && isCorrect)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                if (_showResult && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red, size: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Explanation
              if (_showResult)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentProverb.explanation,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}