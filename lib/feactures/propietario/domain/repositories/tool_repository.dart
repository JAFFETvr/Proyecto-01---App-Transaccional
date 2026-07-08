import 'dart:io';
import '../entitie/tool_entity.dart';

abstract class ToolRepository {
  Future<List<ToolEntity>> getTools();
  Future<ToolEntity> createTool({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
    required double estimatedValue,
    required double dailyRate,
    double? latitude,
    double? longitude,
  });
  Future<ToolEntity> updateTool({
    required String id,
    String? name,
    String? description,
    String? category,
    bool? isAvailable,
    double? estimatedValue,
    double? dailyRate,
    double? latitude,
    double? longitude,
  });
  Future<void> deleteTool(String id);
  Future<Map<String, dynamic>> getPricingSuggestion({
    required double estimatedValue,
    required double scoreCondicion,
    required String category,
    required String brand,
  });
  Future<Map<String, dynamic>> predictCondition(File photo);
  Future<Map<String, dynamic>> autoValuate({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
  });
  Future<String> getSubscriptionPreference();
  Future<bool> confirmSubscriptionPayment(String paymentId);
  Future<bool> refreshIsPro();
}