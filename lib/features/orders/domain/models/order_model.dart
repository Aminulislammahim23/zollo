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
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final String shippingAddress;
  final double shippingFee;
  final OrderStatus status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.shippingFee,
    required this.status,
    required this.createdAt,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get total => subtotal + shippingFee;

  double get totalAmount => total;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  List<String> get _addressLines =>
      shippingAddress.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  /// "Name · phone" from the address snapshot written at checkout.
  String get recipient => _addressLines.length > 1 ? _addressLines.first : '';

  /// The address part of the snapshot.
  String get deliveryAddress =>
      _addressLines.length > 1 ? _addressLines.sublist(1).join(', ') : shippingAddress;

  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.processing;

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'user_id': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'shipping_address': shippingAddress,
        'shipping_fee': shippingFee,
        'total_amount': total,
        'status': status.name,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory OrderModel.fromJson(
    Map<String, dynamic> json, {
    List<OrderItem>? fallbackItems,
  }) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final itemsList = rawItems.isNotEmpty
        ? rawItems.map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);

            return OrderItem(
              productId: item['product_id'] as String? ?? '',
              productName: item['product_name'] as String? ?? '',
              price: ((item['price'] ?? 0) as num).toDouble(),
              quantity: ((item['quantity'] ?? 1) as num).toInt(),
            );
          }).toList()
        : (fallbackItems ?? []);

    return OrderModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      items: itemsList,
      shippingAddress: json['shipping_address'] as String? ?? '',
      shippingFee: ((json['shipping_fee'] ?? 0) as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
