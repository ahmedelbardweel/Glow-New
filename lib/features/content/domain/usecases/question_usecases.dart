import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question_entity.dart';
import '../repositories/content_repository.dart';

class GetQuestionsParams {
  final String missionId;
  final bool forceRefresh;
  GetQuestionsParams(this.missionId, {this.forceRefresh = false});
}

class GetQuestionsUseCase implements UseCase<List<QuestionEntity>, GetQuestionsParams> {
  final ContentRepository repository;

  GetQuestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<QuestionEntity>>> call(GetQuestionsParams params) async {
    return await repository.getQuestions(params.missionId, forceRefresh: params.forceRefresh);
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

class UpdateQuestionUseCase implements UseCase<QuestionEntity, QuestionEntity> {
  final ContentRepository repository;

  UpdateQuestionUseCase(this.repository);

  @override
  Future<Either<Failure, QuestionEntity>> call(QuestionEntity params) async {
    return await repository.updateQuestion(params);
  }
}

class DeleteQuestionUseCase implements UseCase<void, String> {
  final ContentRepository repository;

  DeleteQuestionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteQuestion(params);
  }
}
