abstract final class AppConstants {
  /// Flat delivery fee in taka, used by cart, router and checkout.
  static const double deliveryFee = 60;

  static const String appVersion = '1.0.0';

  static const String privacyPolicyUrl = 'https://zollo.com.bd/privacy';
  static const String termsUrl = 'https://zollo.com.bd/terms';
  static const String supportEmail = 'support@zollo.com.bd';
  static const String productShareBaseUrl = 'https://zollo.com.bd/p';

  /// Social login buttons stay hidden until OAuth is configured in Supabase.
  static const bool showSocialLogin = false;

  static const int returnWindowDays = 7;

  static const List<String> divisions = [
    'Dhaka',
    'Chattogram',
    'Khulna',
    'Rajshahi',
    'Sylhet',
    'Barishal',
    'Rangpur',
    'Mymensingh',
  ];

  static const Map<String, List<String>> districtsByDivision = {
    'Dhaka': [
      'Dhaka City', 'Gazipur', 'Narayanganj', 'Narsingdi', 'Manikganj',
      'Munshiganj', 'Tangail', 'Kishoreganj', 'Faridpur', 'Gopalganj',
      'Madaripur', 'Rajbari', 'Shariatpur',
    ],
    'Chattogram': [
      'Chattogram', "Cox's Bazar", 'Cumilla', 'Feni', 'Noakhali',
      'Lakshmipur', 'Chandpur', 'Brahmanbaria', 'Rangamati', 'Khagrachhari',
      'Bandarban',
    ],
    'Khulna': [
      'Khulna', 'Jashore', 'Satkhira', 'Bagerhat', 'Kushtia', 'Jhenaidah',
      'Magura', 'Narail', 'Chuadanga', 'Meherpur',
    ],
    'Rajshahi': [
      'Rajshahi', 'Bogura', 'Pabna', 'Sirajganj', 'Naogaon', 'Natore',
      'Chapainawabganj', 'Joypurhat',
    ],
    'Sylhet': ['Sylhet', 'Moulvibazar', 'Habiganj', 'Sunamganj'],
    'Barishal': [
      'Barishal', 'Bhola', 'Patuakhali', 'Pirojpur', 'Jhalokati', 'Barguna',
    ],
    'Rangpur': [
      'Rangpur', 'Dinajpur', 'Kurigram', 'Gaibandha', 'Nilphamari',
      'Lalmonirhat', 'Thakurgaon', 'Panchagarh',
    ],
    'Mymensingh': ['Mymensingh', 'Jamalpur', 'Netrokona', 'Sherpur'],
  };
}
