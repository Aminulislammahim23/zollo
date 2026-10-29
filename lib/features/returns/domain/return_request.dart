enum ReturnReason {
  damaged('Item is damaged'),
  wrongItem('Wrong item received'),
  notAsDescribed('Not as described'),
  missingParts('Missing parts'),
  changedMind('Changed my mind');

  const ReturnReason(this.label);
  final String label;
}

class ReturnRequest {
  const ReturnRequest({
    required this.orderId,
    required this.productIds,
    required this.reason,
    this.details = '',
  });

  final String orderId;
  final List<String> productIds;
  final ReturnReason reason;
  final String details;
}
