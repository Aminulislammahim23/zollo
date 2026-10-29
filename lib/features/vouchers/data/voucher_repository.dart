import '../domain/voucher.dart';

abstract interface class VoucherRepository {
  Future<List<Voucher>> getVouchers();

  /// Adds the voucher for [code], or throws [VoucherException].
  Future<Voucher> redeem(String code);
}

class VoucherException implements Exception {
  const VoucherException(this.message);
  final String message;

  @override
  String toString() => message;
}

// TODO(backend): replace with Supabase implementation
class FakeVoucherRepository implements VoucherRepository {
  FakeVoucherRepository({DateTime? now}) : _now = now ?? DateTime.now() {
    _vouchers = [
      Voucher(
        id: 'v1',
        code: 'WELCOME100',
        title: '৳100 off your first order',
        rule: 'Min. spend ৳999 · all sellers',
        amountLabel: '৳100',
        expiresAt: _now.add(const Duration(days: 3)),
      ),
      Voucher(
        id: 'v2',
        code: 'MEGA10',
        title: '10% off electronics',
        rule: 'Up to ৳500 off · Electronics',
        amountLabel: '10%',
        expiresAt: _now.add(const Duration(days: 12)),
      ),
      Voucher(
        id: 'v3',
        code: 'FREESHIP',
        title: 'Free delivery',
        rule: 'Min. spend ৳499 · Dhaka only',
        amountLabel: 'Free',
        expiresAt: _now.add(const Duration(days: 30)),
      ),
    ];
  }

  final DateTime _now;
  late final List<Voucher> _vouchers;

  late final Map<String, Voucher> _redeemable = {
    'ZOLLO50': Voucher(
      id: 'v4',
      code: 'ZOLLO50',
      title: '৳50 off any order',
      rule: 'No minimum spend · all sellers',
      amountLabel: '৳50',
      expiresAt: _now.add(const Duration(days: 7)),
    ),
  };

  @override
  Future<List<Voucher>> getVouchers() async => List.unmodifiable(_vouchers);

  @override
  Future<Voucher> redeem(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) throw const VoucherException('Enter a voucher code.');
    if (_vouchers.any((v) => v.code == normalized)) {
      throw const VoucherException('You already have this voucher.');
    }
    final voucher = _redeemable[normalized];
    if (voucher == null) throw const VoucherException("That code isn't valid or has expired.");
    _vouchers.insert(0, voucher);
    return voucher;
  }
}
