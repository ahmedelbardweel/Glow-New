import 'package:equatable/equatable.dart';

class QuestionEntity extends Equatable {
  final String id;
  final String missionId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  const QuestionEntity({
    required this.id,
    required this.missionId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  @override
  List<Object?> get props => [id, missionId, questionText, options, correctAnswerIndex];
}
