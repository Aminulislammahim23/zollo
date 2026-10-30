import 'payment_method.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;

  /// `order_items.unit_price`: the price charged, frozen at checkout.
  final double price;
  final int quantity;

  /// `order_items.line_total` (unit price × quantity, computed by the DB).
  final double? lineTotal;

  /// `order_items.image_snapshot`: the product photo at checkout.
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.lineTotal,
    this.imageUrl,
  });

  double get subtotal => lineTotal ?? price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final image = json['image_snapshot'] as String?;
    return OrderItem(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      price: ((json['unit_price'] ?? 0) as num).toDouble(),
      quantity: ((json['quantity'] ?? 1) as num).toInt(),
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final String shippingAddress;
  final String shippingName;
  final String shippingPhone;
  final double shippingFee;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;

  /// `orders.total_amount` as charged by the database, when known.
  final double? recordedTotal;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.shippingFee,
    required this.status,
    required this.createdAt,
    this.shippingName = '',
    this.shippingPhone = '',
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.recordedTotal,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get total => recordedTotal ?? subtotal + shippingFee;

  double get totalAmount => total;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get canCancel => status == OrderStatus.pending;

  List<String> get _addressLines => shippingAddress
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// "Name · phone". Older orders stored it as the first line of
  /// [shippingAddress]; orders from `place_order()` have separate columns.
  String get recipient {
    final parts = [
      shippingName,
      shippingPhone,
    ].map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' · ');
    return _addressLines.length > 1 ? _addressLines.first : '';
  }

  /// The address part of the snapshot.
  String get deliveryAddress => shippingName.isEmpty && _addressLines.length > 1
      ? _addressLines.sublist(1).join(', ')
      : _addressLines.join(', ');

  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.processing;

  /// Reads an `orders` row, with its lines embedded by
  /// `select('*, order_items(*)')`.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ?? const [];

    return OrderModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      items: rawItems
          .map(
            (raw) => OrderItem.fromJson(Map<String, dynamic>.from(raw as Map)),
          )
          .toList(),
      shippingAddress: json['shipping_address'] as String? ?? '',
      shippingName: json['shipping_name'] as String? ?? '',
      shippingPhone: json['shipping_phone'] as String? ?? '',
      shippingFee: ((json['shipping_fee'] ?? 0) as num).toDouble(),
      paymentMethod: PaymentMethod.fromDb(json['payment_method'] as String?),
      status: OrderStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      recordedTotal: (json['total_amount'] as num?)?.toDouble(),
    );
  }

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
    id: id,
    userId: userId,
    items: items,
    shippingAddress: shippingAddress,
    shippingName: shippingName,
    shippingPhone: shippingPhone,
    shippingFee: shippingFee,
    paymentMethod: paymentMethod,
    status: status ?? this.status,
    createdAt: createdAt,
    recordedTotal: recordedTotal,
  );
}
