class UserModel {
  final String uid; // Unique User ID from FirebaseAuth
  final String email; // User's email from FirebaseAuth
  final String username; // Custom username
  final String photoUrl; // Profile picture URL
  final DateTime createdAt; // Account creation time and date

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.photoUrl,
    required this.createdAt,
  });

  // Convert to Map (for Firebase Firestore storage)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a UserModel from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
