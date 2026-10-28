import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../services/demo_data.dart';
import 'demo_mode_provider.dart';

final intelligenceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return demoIntelligenceEvents;
  return await ApiClient.instance.listIntelligenceEvents();
});
