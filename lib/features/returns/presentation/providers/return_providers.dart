import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/return_repository.dart';

final returnRepositoryProvider = Provider<ReturnRepository>((ref) {
  return FakeReturnRepository();
});
