import '../domain/return_request.dart';

abstract interface class ReturnRepository {
  Future<void> submit(ReturnRequest request);
}

// TODO(backend): replace with Supabase implementation
class FakeReturnRepository implements ReturnRepository {
  final List<ReturnRequest> submitted = [];

  @override
  Future<void> submit(ReturnRequest request) async {
    if (request.productIds.isEmpty) {
      throw ArgumentError('Choose at least one item to return.');
    }
    submitted.add(request);
  }
}
