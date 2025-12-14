// lib/services/score_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_score.dart';

class ScoreService {
  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  List<GameScore> _scores = [];

  List<GameScore> get scores => _scores;

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString('game_scores');
    if (scoresJson != null) {
      final List<dynamic> decoded = json.decode(scoresJson);
      _scores = decoded.map((e) => GameScore.fromJson(e)).toList();
      _scores.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> saveScore(GameScore score) async {
    _scores.add(score);
    _scores.sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    final scoresJson = json.encode(_scores.map((e) => e.toJson()).toList());
    await prefs.setString('game_scores', scoresJson);
  }

  int getBestScore(String gameType) {
    final gameScores = _scores.where((s) => s.gameType == gameType);
    if (gameScores.isEmpty) return 0;
    return gameScores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
  }

  int getTotalGamesPlayed() {
    return _scores.length;
  }

  List<GameScore> getTopScores({int limit = 10}) {
    final sortedScores = List<GameScore>.from(_scores);
    sortedScores.sort((a, b) => b.score.compareTo(a.score));
    return sortedScores.take(limit).toList();
  }

  List<GameScore> getScoresByGame(String gameType) {
    return _scores.where((s) => s.gameType == gameType).toList();
  }

  Map<String, int> getGameStats() {
    final stats = <String, int>{};
    for (var score in _scores) {
      stats[score.gameType] = (stats[score.gameType] ?? 0) + 1;
    }
    return stats;
  }
}