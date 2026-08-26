// lib/domain/usecases/diagnosis/get_disease_explanation_use_case.dart

import '../../entities/disease_explanation.dart';
import '../../repositories/disease_explanation_repository.dart';

class GetDiseaseExplanationUseCase {
  final DiseaseExplanationRepository repository;

  GetDiseaseExplanationUseCase(this.repository);

  Future<DiseaseExplanation?> call({
    required String diseaseId,
    required String languageCode,
  }) {
    return repository.getExplanation(
      diseaseId: diseaseId,
      languageCode: languageCode,
    );
  }
}
