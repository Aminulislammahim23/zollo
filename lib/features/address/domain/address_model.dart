class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String postalCode;
  final String country;
  final String division;
  final String district;
  final String area;
  final String label;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    this.country = 'Bangladesh',
    this.division = 'Dhaka',
    this.district = 'Dhaka City',
    this.area = 'Dhanmondi',
    this.label = 'HOME',
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedAddress => '$addressLine, $city - $postalCode';

  /// "House 12, Road 4, Dhanmondi, Dhaka City, Dhaka".
  String get displayAddress {
    final parts = <String>[
      addressLine,
      area,
      district,
      division,
    ].map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    // Drop consecutive duplicates such as "Dhaka City, Dhaka City".
    final unique = <String>[];
    for (final p in parts) {
      if (unique.isEmpty || unique.last.toLowerCase() != p.toLowerCase()) {
        unique.add(p);
      }
    }
    if (unique.isEmpty) return formattedAddress;
    return postalCode.trim().isEmpty
        ? unique.join(', ')
        : '${unique.join(', ')} - $postalCode';
  }

  /// "Dhanmondi, Dhaka City".
  String get shortArea {
    final parts = [
      area,
      district,
    ].map((p) => p.trim()).where((p) => p.isNotEmpty);
    return parts.isEmpty ? city : parts.join(', ');
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      fullName:
          map['recipient_name'] as String? ?? map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      addressLine:
          map['address_line'] as String? ??
          map['full_address'] as String? ??
          '',
      city: map['city'] as String? ?? '',
      postalCode: map['postal_code'] as String? ?? '',
      country: map['country'] as String? ?? 'Bangladesh',
      division: map['division'] as String? ?? 'Dhaka',
      district:
          map['district'] as String? ?? map['city'] as String? ?? 'Dhaka City',
      area: map['area'] as String? ?? '',
      label: map['label'] as String? ?? 'HOME',
      isDefault: map['is_default'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Columns the app writes; `user_id` and `is_default` are set by the
  /// repository. The label is stored lowercase ('home' / 'office' / 'other').
  Map<String, dynamic> toWriteMap() => {
    'recipient_name': fullName,
    'phone': phone,
    'address_line': addressLine,
    'city': city,
    'postal_code': postalCode.isEmpty ? null : postalCode,
    'country': country,
    'division': division,
    'district': district,
    'area': area,
    'label': label.toLowerCase(),
  };

  Address copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? addressLine,
    String? city,
    String? postalCode,
    String? country,
    String? division,
    String? district,
    String? area,
    String? label,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      division: division ?? this.division,
      district: district ?? this.district,
      area: area ?? this.area,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
