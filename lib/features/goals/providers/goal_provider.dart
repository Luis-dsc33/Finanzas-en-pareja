import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/goal_models.dart';
import '../../../services/firebase/goal_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

final goalsDataProvider = StreamProvider<FinancialGoalsData>((ref) {
  final service = ref.watch(goalServiceProvider);
  return service.watchGoalsData();
});
