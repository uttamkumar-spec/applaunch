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
}
