import 'package:hive/hive.dart';

part 'challenge_model.g.dart';

@HiveType(typeId: 0)
class ChallengeEntry extends HiveObject {
  @HiveField(0)
  final String challengeText;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<String> modifiers;

  @HiveField(3)
  final bool completed;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String difficulty;

  @HiveField(6)
  final String id;

  ChallengeEntry({
    required this.challengeText,
    required this.date,
    required this.modifiers,
    required this.completed,
    required this.category,
    required this.difficulty,
    required this.id,
  });

  Map<String, dynamic> toMap() => {
    'challengeText': challengeText,
    'date': date.toIso8601String(),
    'modifiers': modifiers,
    'completed': completed,
    'category': category,
    'difficulty': difficulty,
    'id': id,
  };

  static ChallengeEntry fromMap(Map<String, dynamic> map) => ChallengeEntry(
    challengeText: map['challengeText'],
    date: DateTime.parse(map['date']),
    modifiers: List<String>.from(map['modifiers']),
    completed: map['completed'],
    category: map['category'] ?? 'general',
    difficulty: map['difficulty'] ?? 'easy',
    id: map['id'] ?? '',
  );
}

@HiveType(typeId: 1)
class Modifier {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final int points;

  @HiveField(3)
  final String icon;

  Modifier({
    required this.id,
    required this.text,
    required this.points,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'points': points,
    'icon': icon,
  };

  static Modifier fromMap(Map<String, dynamic> map) => Modifier(
    id: map['id'],
    text: map['text'],
    points: map['points'],
    icon: map['icon'],
  );
}
