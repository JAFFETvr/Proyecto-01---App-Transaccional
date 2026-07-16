import 'dart:io';
import '../../domain/entitie/tool_entity.dart';
import '../../domain/repositories/tool_repository.dart';
import '../datasoruce/tool_remote_datasource.dart';

class ToolRepositoryImpl implements ToolRepository {
  final ToolRemoteDatasource _datasource;
  const ToolRepositoryImpl(this._datasource);

  @override Future<List<ToolEntity>> getTools() =>
      _datasource.getTools();

  @override Future<ToolEntity> createTool({
    required String name, required String description,
    required String category, required bool isAvailable,
    required double estimatedValue, required double dailyRate,
    double? latitude, double? longitude,
    String brand = 'Generico', int ageMonths = 12,
    double conditionScore = 0.70,
  }) => _datasource.createTool(
        name: name, description: description,
        category: category, isAvailable: isAvailable,
        estimatedValue: estimatedValue, dailyRate: dailyRate,
        latitude: latitude, longitude: longitude,
        brand: brand, ageMonths: ageMonths,
        conditionScore: conditionScore);

  @override Future<ToolEntity> updateTool({
    required String id, String? name, String? description,
    String? category, bool? isAvailable,
    double? estimatedValue, double? dailyRate,
    double? latitude, double? longitude,
  }) => _datasource.updateTool(
        id: id, name: name, description: description,
        category: category, isAvailable: isAvailable,
        estimatedValue: estimatedValue, dailyRate: dailyRate,
        latitude: latitude, longitude: longitude);

  @override Future<void> deleteTool(String id) =>
      _datasource.deleteTool(id);

  @override Future<ToolEntity> uploadPhoto(String toolId, File photo) =>
      _datasource.uploadPhoto(toolId, photo);

  @override Future<Map<String, dynamic>> getPricingSuggestion({
    required double estimatedValue,
    required double scoreCondicion,
    required String category,
    required String brand,
  }) => _datasource.getPricingSuggestion(
        estimatedValue: estimatedValue,
        scoreCondicion: scoreCondicion,
        category: category,
        brand: brand);

  @override Future<Map<String, dynamic>> predictCondition(File photo) =>
      _datasource.predictCondition(photo);

  @override Future<Map<String, dynamic>> autoValuate({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
    int? ageMonths,
  }) => _datasource.autoValuate(
        name: name,
        scoreCondicion: scoreCondicion,
        category: category,
        brand: brand,
        ageMonths: ageMonths);

  @override Future<String> getSubscriptionPreference() => _datasource.getSubscriptionPreference();
  @override Future<bool> confirmSubscriptionPayment(String paymentId) => _datasource.confirmSubscriptionPayment(paymentId);
  @override Future<bool> refreshIsPro() => _datasource.refreshIsPro();
}