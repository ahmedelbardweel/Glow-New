import '../entities/linked_child.dart';

abstract class ParentChildrenRepository {
  Future<List<LinkedChild>> listForCurrentParent();

  /// False when no parent session exists. Throws when the server rejects the code.
  Future<bool> link(String code);
}
