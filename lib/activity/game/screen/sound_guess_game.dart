// lib/screens/sound_guess_game.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart'; // 1. Import thư viện TTS
import 'package:nhoapp/activity/game/services/score_service.dart';
import '../models/game_score.dart';

class SoundGuessGame extends StatefulWidget {
  const SoundGuessGame({Key? key}) : super(key: key);

  @override
  State<SoundGuessGame> createState() => _SoundGuessGameState();
}

class _SoundGuessGameState extends State<SoundGuessGame> {
  final ScoreService _scoreService = ScoreService();
  final FlutterTts _flutterTts = FlutterTts(); // 2. Khai báo biến TTS

  final List<SoundItem> _sounds = [
    SoundItem(
      name: 'Gà',
      soundDescription: 'Ò ó o... Ò ó o...',
      options: ['Gà', 'Vịt', 'Ngỗng', 'Chim'],
      correctAnswer: 0,
    ),
    SoundItem(
      name: 'Chó',
      soundDescription: 'Gâu gâu... Gâu gâu...',
      options: ['Mèo', 'Chó', 'Heo', 'Cừu'],
      correctAnswer: 1,
    ),
    SoundItem(
      name: 'Mèo',
      soundDescription: 'Meo meo... Meo meo...',
      options: ['Chó', 'Hổ', 'Mèo', 'Sư tử'],
      correctAnswer: 2,
    ),
    SoundItem(
      name: 'Bò',
      soundDescription: 'Ủm bò... Ủm bò...',
      options: ['Bò', 'Trâu', 'Dê', 'Cừu'],
      correctAnswer: 0,
    ),
    SoundItem(
      name: 'Vịt',
      soundDescription: 'Cạp cạp... Cạp cạp...',
      options: ['Gà', 'Vịt', 'Ngỗng', 'Thiên nga'],
      correctAnswer: 1,
    ),
    SoundItem(
      name: 'Lợn',
      soundDescription: 'Éc éc... Éc éc...',
      options: ['Trâu', 'Bò', 'Dê', 'Lợn'],
      correctAnswer: 3,
    ),
    SoundItem(
      name: 'Ngựa',
      soundDescription: 'Hí... Hí...',
      options: ['Ngựa', 'Lừa', 'Trâu', 'Bò'],
      correctAnswer: 0,
    ),
    SoundItem(
      name: 'Ếch',
      soundDescription: 'Ộp ộp... Ộp ộp...',
      options: ['Ếch', 'Cóc', 'Rắn', 'Thằn lằn'],
      correctAnswer: 0,
    ),
    SoundItem(
      name: 'Ong',
      soundDescription: 'Vù vù... Vù vù...',
      options: ['Muỗi', 'Ong', 'Ruồi', 'Bọ'],
      correctAnswer: 1,
    ),
    SoundItem(
      name: 'Chim',
      soundDescription: 'Chíp chíp... Chíp chíp...',
      options: ['Dơi', 'Chim', 'Bướm', 'Cú'],
      correctAnswer: 1,
    ),
  ];

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _soundPlaying = false;
  List<SoundItem> _shuffledSounds = [];

  @override
  void initState() {
    super.initState();
    _shuffledSounds = List.from(_sounds)..shuffle();
    _initTts(); // 3. Khởi tạo cấu hình TTS
  }

  // 4. Cấu hình TTS
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN"); // Thiết lập tiếng Việt
    await _flutterTts.setSpeechRate(0.4); // Tốc độ đọc chậm lại một chút để giống tiếng kêu
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Lắng nghe khi đọc xong để tắt trạng thái loading
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _soundPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Dừng đọc khi thoát màn hình
    super.dispose();
  }

  // 5. Hàm phát âm thanh mới
  Future<void> _playSound() async {
    setState(() {
      _soundPlaying = true;
    });

    String textToSpeak = _shuffledSounds[_currentIndex].soundDescription;
    await _flutterTts.speak(textToSpeak);

    // Lưu ý: State _soundPlaying sẽ được set về false trong setCompletionHandler ở trên
  }

  void _selectAnswer(int index) {
    if (_showResult) return;

    // Dừng đọc nếu người dùng chọn đáp án
    _flutterTts.stop();
    if(mounted) {
      setState(() {
        _soundPlaying = false;
      });
    }

    setState(() {
      _selectedAnswer = index;
      _showResult = true;

      if (index == _shuffledSounds[_currentIndex].correctAnswer) {
        _score += 10;
      }
    });

    Timer(const Duration(seconds: 2), () {
      if (_currentIndex < _shuffledSounds.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _showResult = false;
        });
        // Có thể tự động phát âm thanh câu tiếp theo nếu muốn:
        // _playSound();
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    _scoreService.saveScore(GameScore(
      gameType: 'sound_guess',
      score: _score,
      date: DateTime.now(),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎵 Tuyệt Vời!',
          style: TextStyle(color: Color(0xFF81C784), fontSize: 24),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã đoán đúng ${_score ~/ 10}/${_shuffledSounds.length} âm thanh',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_score điểm',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF81C784),
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
                _shuffledSounds.shuffle();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
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
    final currentSound = _shuffledSounds[_currentIndex];

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
          'Nghe Âm Đoán Vật',
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
                    'Câu ${_currentIndex + 1}/${_shuffledSounds.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFF81C784), size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '$_score điểm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF81C784),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _shuffledSounds.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 40),

              // Sound Player
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF81C784), Color(0xFFA5D6A7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF81C784).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.hearing,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hãy nghe âm thanh',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _soundPlaying ? null : _playSound,
                      icon: Icon(
                        _soundPlaying ? Icons.volume_up : Icons.play_arrow,
                        size: 32,
                      ),
                      label: Text(
                        _soundPlaying ? 'Đang phát...' : 'Nghe âm thanh',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF81C784),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    if (_soundPlaying) ...[
                      const SizedBox(height: 20),
                      Text(
                        "Đang đọc: ${currentSound.soundDescription}", // Hiển thị text đang đọc để debug hoặc người dùng xem
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Question
              Text(
                'Đây là tiếng con gì?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: currentSound.options.length,
                  itemBuilder: (context, index) {
                    final isCorrect = index == currentSound.correctAnswer;
                    final isSelected = _selectedAnswer == index;

                    Color getColor() {
                      if (!_showResult) return Colors.white;
                      if (isSelected && isCorrect) return Colors.green[50]!;
                      if (isSelected && !isCorrect) return Colors.red[50]!;
                      if (isCorrect) return Colors.green[50]!;
                      return Colors.white;
                    }

                    Color getBorderColor() {
                      if (!_showResult) return const Color(0xFF81C784);
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
                                    currentSound.options[index],
                                    style: TextStyle(
                                      fontSize: 20,
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
            ],
          ),
        ),
      ),
    );
  }
}