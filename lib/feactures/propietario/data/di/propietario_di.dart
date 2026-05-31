import '../datasoruce/tool_remote_datasource.dart';
import '../repositories/tool_repository_impl.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart';
import '../../domain/usesCases/delete_tool_usecase.dart';

class PropietarioDI {
  static final _datasource  = ToolRemoteDatasource();
  static final _repository  = ToolRepositoryImpl(_datasource);

  static GetToolsUseCase    provideGetTools()    => GetToolsUseCase(_repository);
  static CreateToolUseCase  provideCreateTool()  => CreateToolUseCase(_repository);
  static UpdateToolUseCase  provideUpdateTool()  => UpdateToolUseCase(_repository);
  static DeleteToolUseCase  provideDeleteTool()  => DeleteToolUseCase(_repository);
}