import '../datasoruce/tool_remote_datasource.dart';
import '../repositories/tool_repository_impl.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart';
import '../../domain/usesCases/delete_tool_usecase.dart';
import '../../domain/usesCases/predict_condition_usecase.dart';
import '../../domain/usesCases/auto_valuate_usecase.dart';
import '../../domain/usesCases/upload_tool_photo_usecase.dart';

import '../../domain/usesCases/get_pricing_suggestion_usecase.dart';
import '../../domain/usesCases/subscribe_usecase.dart';

class PropietarioDI {
  static final _datasource  = ToolRemoteDatasource();
  static final _repository  = ToolRepositoryImpl(_datasource);

  static GetToolsUseCase    provideGetTools()    => GetToolsUseCase(_repository);
  static CreateToolUseCase  provideCreateTool()  => CreateToolUseCase(_repository);
  static UpdateToolUseCase  provideUpdateTool()  => UpdateToolUseCase(_repository);
  static DeleteToolUseCase  provideDeleteTool()  => DeleteToolUseCase(_repository);
  static GetPricingSuggestionUseCase provideGetPricingSuggestion() =>
      GetPricingSuggestionUseCase(_repository);
  static PredictConditionUseCase providePredictCondition() =>
      PredictConditionUseCase(_repository);
  static AutoValuateUseCase provideAutoValuate() =>
      AutoValuateUseCase(_repository);
  static UploadToolPhotoUseCase provideUploadToolPhoto() =>
      UploadToolPhotoUseCase(_repository);
  static GetSubscriptionPreferenceUseCase provideGetSubscriptionPreference() =>
      GetSubscriptionPreferenceUseCase(_repository);
  static ConfirmSubscriptionPaymentUseCase provideConfirmSubscriptionPayment() =>
      ConfirmSubscriptionPaymentUseCase(_repository);
  static RefreshIsProUseCase provideRefreshIsPro() =>
      RefreshIsProUseCase(_repository);
}