import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/session/app_session.dart';
import '../domain/entities/linked_child.dart';
import '../domain/repositories/parent_children_repository.dart';

class SupabaseParentChildrenRepository implements ParentChildrenRepository {
  SupabaseParentChildrenRepository(this._client, this._session);

  final SupabaseClient _client;
  final AppSession _session;

  @override
  Future<List<LinkedChild>> listForCurrentParent() async {
    final parentId = _session.userId;
    if (parentId == null) return const [];
    final rows = await _client
        .from('children_profiles')
        .select()
        .eq('parent_id', parentId);
    return [
      for (final row in rows)
        LinkedChild(
          id: row['id'] as String,
          name: (row['name'] as String?) ?? '',
          age: (row['age'] as num?)?.toInt() ?? 0,
          code: (row['child_code'] as String?) ?? '',
        ),
    ];
  }

  @override
  Future<bool> link(String code) async {
    final parentId = _session.userId;
    if (parentId == null) return false;
    await _client.rpc('link_parent_to_child', params: {
      'p_parent_id': parentId,
      'p_child_code': code,
    });
    return true;
  }
}
