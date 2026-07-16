import 'dart:io';
import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class UploadToolPhotoUseCase {
  final ToolRepository _repository;
  const UploadToolPhotoUseCase(this._repository);

  Future<ToolEntity> execute(String toolId, File photo) {
    return _repository.uploadPhoto(toolId, photo);
  }
}
