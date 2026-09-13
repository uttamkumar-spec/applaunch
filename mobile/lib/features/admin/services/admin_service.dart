import '../../../core/models/guardrail_rule.dart';
import '../../../services/api_client.dart';
import '../models/admin_models.dart';

class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  Future<List<AppUser>> fetchUsers() async {
    try {
      final res = await _api.get('/admin/users') as List;
      return res.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _api.post('/admin/users', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<PlatformLimits> fetchLimits() async {
    try {
      final res = await _api.get('/admin/limits');
      return PlatformLimits.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return PlatformLimits.fromJson(const {});
    }
  }

  Future<void> updateLimits(PlatformLimits limits) async {
    await _api.put('/admin/limits', body: limits.toJson());
  }

  // --- Platform-wide guardrails: which athlete AI chat questions are safe
  // to auto-answer everywhere, vs. always routed to a coach ---

  Future<List<GuardrailRule>> fetchGuardrails() async {
    try {
      final res = await _api.get('/admin/guardrails') as List;
      return res.map((r) => GuardrailRule.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createGuardrail(GuardrailRule rule) async {
    await _api.post('/admin/guardrails', body: rule.toJson());
  }

  Future<void> updateGuardrail(String id, GuardrailRule rule) async {
    await _api.put('/admin/guardrails/$id', body: rule.toJson());
  }

  Future<void> deleteGuardrail(String id) async {
    await _api.delete('/admin/guardrails/$id');
  }
}
