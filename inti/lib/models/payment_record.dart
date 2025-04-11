class PaymentRecord {
  final String address;
  final int postcode;
  final String country;
  final String primaryEmail;
  final String alternativeEmail;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final double savingsAccount;

  PaymentRecord({
    required this.address,
    required this.postcode,
    required this.country,
    required this.primaryEmail,
    required this.alternativeEmail,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    required this.savingsAccount,
  });

  // Convert a PaymentRecord object to a Map
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'postcode': postcode,
      'country': country,
      'primryEmail': primaryEmail,
      'alternativeEmail': alternativeEmail,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'savingsAccount': savingsAccount,
    };
  }

  // Create a PaymentRecord object from a Map
  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      address: map['address'] ?? '',
      postcode: map['postcode'] ?? 0,
      country: map['country'] ?? '',
      primaryEmail: map['primaryEmail'] ?? '',
      alternativeEmail: map['alternativeEmail'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactNumber: map['emergencyContactNumber'] ?? '',
      savingsAccount:
          (map['savingsAccount'] is num)
              ? (map['savingsAccount'] as num).toDouble()
              : 0.0,
    );
  }
}
