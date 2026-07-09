import '../../../core/network/api_client.dart';
import '../domain/branch_models.dart';

class BranchesRepository {
  BranchesRepository(this._api);

  final ApiClient _api;

  Future<List<Branch>> fetchBranches() async {
    final data = await _api.getList('/branches');
    return data
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Branch>> fetchAdminBranches() async {
    final data = await _api.getList('/admin/branches');
    return data
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
