import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question_entity.dart';
import '../repositories/content_repository.dart';

class GetQuestionsUseCase implements UseCase<List<QuestionEntity>, String> {
  final ContentRepository repository;

  GetQuestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<QuestionEntity>>> call(String missionId) async {
    return await repository.getQuestions(missionId);
  }
}

class AddQuestionUseCase implements UseCase<QuestionEntity, QuestionEntity> {
  final ContentRepository repository;

  AddQuestionUseCase(this.repository);

  @override
  Future<Either<Failure, QuestionEntity>> call(QuestionEntity params) async {
    return await repository.addQuestion(params);
  }
}
