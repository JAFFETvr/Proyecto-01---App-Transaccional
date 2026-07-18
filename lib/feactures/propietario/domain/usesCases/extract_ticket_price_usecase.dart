import 'dart:io';
import '../repositories/tool_repository.dart';

class ExtractTicketPriceUseCase {
  final ToolRepository _repository;
  const ExtractTicketPriceUseCase(this._repository);

  Future<Map<String, dynamic>> execute(File photo) {
    return _repository.extractTicketPrice(photo);
  }
}
