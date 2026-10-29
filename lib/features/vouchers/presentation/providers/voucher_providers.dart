import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/voucher_repository.dart';
import '../../domain/voucher.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return FakeVoucherRepository();
});

final vouchersProvider = AsyncNotifierProvider<VouchersController, List<Voucher>>(
  VouchersController.new,
);

class VouchersController extends AsyncNotifier<List<Voucher>> {
  @override
  Future<List<Voucher>> build() => ref.read(voucherRepositoryProvider).getVouchers();

  /// Throws [VoucherException] for an invalid code.
  Future<Voucher> redeem(String code) async {
    final voucher = await ref.read(voucherRepositoryProvider).redeem(code);
    state = AsyncData(await ref.read(voucherRepositoryProvider).getVouchers());
    return voucher;
  }
}
