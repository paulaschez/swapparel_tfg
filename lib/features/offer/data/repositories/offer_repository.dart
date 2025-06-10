import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/offer_model.dart';
import '../../../../core/constants/firestore_collections.dart'; // Para matchesCollection

abstract class OfferRepository {
  Future<void> createOffer(String matchId, OfferModel offerData);
  Future<void> updateOfferStatus(
    String matchId,
    String offerId,
    OfferStatus newStatus, {
    Transaction? transaction, // Parámetro opcional
  });
  Stream<List<OfferModel>> getOfferStreamForMatch(String matchId);
}

class OfferRepositoryImpl implements OfferRepository {
  final FirebaseFirestore _firestore;

  OfferRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<void> createOffer(String matchId, OfferModel offerData) async {
    if (matchId.isEmpty) throw ArgumentError("matchId cannot be empty");
    try {
      // Añadir la oferta a la subcolección 'offers' del match
      final offerRef =
          _firestore
              .collection(matchesCollection)
              .doc(matchId)
              .collection(offersCollection)
              .doc();

      Map<String, dynamic> dataToSave = offerData.toJson();

      await offerRef.set(dataToSave);
      print("OfferRepo: Oferta creada en match $matchId con ID ${offerRef.id}");
    } catch (e) {
      print("OfferRepo Error - createOffer: $e");
      throw Exception("Failed to create offer.");
    }
  }

  @override
  Future<void> updateOfferStatus(
    String matchId,
    String offerId,
    OfferStatus newStatus, {
    Transaction? transaction, // Parámetro opcional
  }) async {
    if (matchId.isEmpty || offerId.isEmpty) {
      throw ArgumentError("matchId or offerId cannot be empty");
    }

    final DocumentReference offerDocRef = _firestore
        .collection(matchesCollection)
        .doc(matchId)
        .collection(offersCollection)
        .doc(offerId);

    final Map<String, dynamic> dataToUpdate = {
      'status': newStatus.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (transaction != null) {
        // Usar la transacción si se proporciona
        transaction.update(offerDocRef, dataToUpdate);
        print(
          "OfferRepo (TX): Estado de oferta $offerId en match $matchId actualizado a $newStatus",
        );
      } else {
        // Operación normal si no hay transacción
        await offerDocRef.update(dataToUpdate);
        print(
          "OfferRepo: Estado de oferta $offerId en match $matchId actualizado a $newStatus",
        );
      }
    } catch (e) {
      print(
        "OfferRepo Error - updateOfferStatus (Offer: $offerId, Match: $matchId, TX: ${transaction != null}): $e",
      );
      throw Exception("Failed to update offer status for offer $offerId.");
    }
  }

  @override
  Stream<List<OfferModel>> getOfferStreamForMatch(String matchId) {
    if (matchId.isEmpty) return Stream.value([]);
    try {
      return _firestore
          .collection(matchesCollection)
          .doc(matchId)
          .collection('offers')
          .orderBy(
            'createdAt',
            descending: false,
          ) // Mostrar ofertas en orden de creación
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (doc) => OfferModel.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      print("OfferRepo Error - getOfferStreamForMatch: $e");
      return Stream.error(Exception("Failed to get offers."));
    }
  }
}
