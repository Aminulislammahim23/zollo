class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.rule,
    required this.amountLabel,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final String title;

  /// e.g. "Min. spend ৳999 · all sellers".
  final String rule;

  /// Big label on the ticket: "৳100", "10%", "Free".
  final String amountLabel;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}
