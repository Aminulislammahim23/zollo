import 'package:flutter_test/flutter_test.dart';
import 'package:zollo/features/address/domain/address_model.dart';

void main() {
  test('writes label, division, district and area', () {
    final address = Address(
      id: 'a1',
      userId: 'user-1',
      fullName: 'Rahim Uddin',
      phone: '01712345678',
      addressLine: 'House 12, Road 4',
      city: 'Chattogram',
      postalCode: '',
      division: 'Chattogram',
      district: 'Cox\'s Bazar',
      area: 'Kolatoli',
      label: 'Office',
      isDefault: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final map = address.toWriteMap();
    expect(map['label'], 'office');
    expect(map['division'], 'Chattogram');
    expect(map['district'], 'Cox\'s Bazar');
    expect(map['area'], 'Kolatoli');
    expect(map['postal_code'], isNull);
    // The repository promotes defaults through set_default_address().
    expect(map.containsKey('is_default'), isFalse);
    expect(map.containsKey('user_id'), isFalse);
  });

  test('reads the structured columns back', () {
    final address = Address.fromMap({
      'id': 'a1',
      'user_id': 'user-1',
      'recipient_name': 'Rahim Uddin',
      'phone': '01712345678',
      'address_line': 'House 12',
      'division': 'Sylhet',
      'district': 'Sylhet',
      'area': 'Zindabazar',
      'label': 'other',
      'is_default': true,
    });
    expect(address.label, 'other');
    expect(address.shortArea, 'Zindabazar, Sylhet');
    expect(address.displayAddress, 'House 12, Zindabazar, Sylhet');
    expect(address.isDefault, isTrue);
  });
}
