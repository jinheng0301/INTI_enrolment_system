class PaymentRecord {
  final String paymentId;
  final String address;
  final int postcode;
  final String country;
  final String primaryEmail;
  final String alternativeEmail;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final double savingsAccount;
  final String status; // Added status field

  PaymentRecord({
    required this.paymentId,
    required this.address,
    required this.postcode,
    required this.country,
    required this.primaryEmail,
    required this.alternativeEmail,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    required this.savingsAccount,
    this.status = 'pending', // Default status is pending
  });

  // Convert a PaymentRecord object to a Map
  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId, // Added paymentId to map
      'address': address,
      'postcode': postcode,
      'country': country,
      'primaryEmail': primaryEmail,
      'alternativeEmail': alternativeEmail,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'savingsAccount': savingsAccount,
      'status': status, // Include status in map
    };
  }

  // Create a PaymentRecord object from a Map
  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      paymentId: map['paymentId'] ?? '',
      address: map['address'] ?? '',
      postcode: map['postcode'] ?? 0,
      country: map['country'] ?? '',
      primaryEmail:
          map['primaryEmail'] ??
          map['primryEmail'] ??
          '', // Handle both keys for backward compatibility
      alternativeEmail: map['alternativeEmail'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactNumber: map['emergencyContactNumber'] ?? '',
      savingsAccount:
          (map['savingsAccount'] is num)
              ? (map['savingsAccount'] as num).toDouble()
              : 0.0,
      status: map['status'] ?? 'pending',
    );
  }
}
