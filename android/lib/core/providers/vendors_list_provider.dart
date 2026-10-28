import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/vendor.dart';
import '../services/demo_data.dart';
import 'demo_mode_provider.dart';

final vendorsListProvider = FutureProvider<List<Vendor>>((ref) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return demoVendors;
  final data = await ApiClient.instance.listVendors();
  return data.map((json) => Vendor.fromJson(json)).toList();
});
