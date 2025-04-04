import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inti/models/drop_request.dart';

final dropRequestsProvider = StreamProvider.autoDispose<List<DropRequest>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('drop_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => DropRequest.fromFirestore(doc)).toList(),
      );
});
