import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/enrollment_for_approve_and_reject.dart';

final enrollmentsStreamProvider =
    StreamProvider.autoDispose<List<EnrollmentForApproveAndReject>>((ref) {
      return FirebaseFirestore.instance
          .collection('enrollments')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => EnrollmentForApproveAndReject.fromMap(
                        doc.data(),
                        doc.id,
                      ),
                    )
                    .toList(),
          );
    });
