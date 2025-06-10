import 'package:cloud_firestore/cloud_firestore.dart';

class OfferedItemInfo {
  final String garmentId;
  final String name;
  final String? imageUrl; 

  OfferedItemInfo({
    required this.garmentId,
    required this.name,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'garmentId': garmentId,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  factory OfferedItemInfo.fromJson(Map<String, dynamic> json) {
    return OfferedItemInfo(
      garmentId: json['garmentId'] as String? ?? '',
      name: json['name'] as String? ?? 'Prenda desconocida',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

// Posibles estados de una oferta
enum OfferStatus { pending, accepted, declined }

class OfferModel {
  final String id;                  // ID autogenerado del documento de la oferta
  final String matchId;             // ID del match/chat al que pertenece
  final String offeringUserId;      // UID del usuario que hace la oferta
  final String receivingUserId;     // UID del usuario que recibe la oferta
  final List<OfferedItemInfo> offeredItems;  // Prendas ofrecidas por offeringUserId
  final List<OfferedItemInfo> requestedItems; // Prendas solicitadas de receivingUserId
  final Timestamp createdAt;
  Timestamp? updatedAt;          // Para saber cuándo se actualizó el estado
  OfferStatus status; // Estado en el que se encuentra la oferta (pendiente, aceptada, rechazada)

  OfferModel({
    required this.id,
    required this.matchId,
    required this.offeringUserId,
    required this.receivingUserId,
    required this.offeredItems,
    required this.requestedItems,
    required this.createdAt,
    this.updatedAt,
    this.status = OfferStatus.pending, // Por defecto, una oferta está pendiente
  });

  factory OfferModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for OfferModel id: ${doc.id}');
    }

    // Convertir la lista de mapas de items a lista de OfferedItemInfo
    List<OfferedItemInfo> parseItems(dynamic itemsData) {
      if (itemsData is List) {
        return itemsData
            .map((item) => OfferedItemInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return OfferModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      offeringUserId: data['offeringUserId'] ?? '',
      receivingUserId: data['receivingUserId'] ?? '',
      offeredItems: parseItems(data['offeredItems']),
      requestedItems: parseItems(data['requestedItems']),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      status: OfferStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => OfferStatus.pending, 
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'offeringUserId': offeringUserId,
      'receivingUserId': receivingUserId,
      'offeredItems': offeredItems.map((item) => item.toJson()).toList(),
      'requestedItems': requestedItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? createdAt, 
      'status': status.toString(), 
    };
  }
}