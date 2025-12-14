// lib/models/game_score.dart
class GameScore {
  final String gameType;
  final int score;
  final DateTime date;
  final int level;

  GameScore({
    required this.gameType,
    required this.score,
    required this.date,
    this.level = 1,
  });

  Map<String, dynamic> toJson() => {
    'gameType': gameType,
    'score': score,
    'date': date.toIso8601String(),
    'level': level,
  };

  factory GameScore.fromJson(Map<String, dynamic> json) => GameScore(
    gameType: json['gameType'],
    score: json['score'],
    date: DateTime.parse(json['date']),
    level: json['level'] ?? 1,
  );
}

class Proverb {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  Proverb({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}


class SoundItem {
  final String name;
  final String soundDescription;
  final List<String> options;
  final int correctAnswer;

  SoundItem({
    required this.name,
    required this.soundDescription,
    required this.options,
    required this.correctAnswer,
  });
}