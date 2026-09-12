import '../../domain/entities/question_entity.dart';

class QuestionModel extends QuestionEntity {
  const QuestionModel({
    required super.id,
    required super.missionId,
    required super.questionText,
    required super.options,
    required super.correctAnswerIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      questionText: json['question_text'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correct_answer_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'mission_id': missionId,
      'question_text': questionText,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
    };
  }
}
