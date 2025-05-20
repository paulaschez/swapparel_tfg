import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/garment_model.dart';
import '../../../../app/config/constants/firestore_collections.dart';

abstract class GarmentRepository {
  Future<List<String>> uploadGarmentImages({
    required String userId,
    required String garmentId,
    required List<XFile> imageFiles,
  });
  Future<void> addGarmentData(GarmentModel garmentData);
  Future<GarmentModel?> getGarmentById(String garmentId);
  Future<void> updateGarmentData(
    String garmentId,
    Map<String, dynamic> dataToUpdate,
  );
  Future<void> deleteGarment(String garmentId, List<String> imageUrls);
}

class GarmentRepositoryImpl implements GarmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  GarmentRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage,
       _uuid = const Uuid();

  @override
  Future<void> addGarmentData(GarmentModel garmentData) async {
    try {
      await _firestore
          .collection(garmentsCollection)
          .doc(garmentData.id)
          .set(garmentData.toJson());
      print(
        "GarmentRepo: Datos de prenda añadidos a Firestore con ID: ${garmentData.id}",
      );
    } catch (e) {
      print("GarmentRepo Error - addGarmentData: $e");
      throw Exception("Failed to add garment data to Firestore.");
    }
  }

  @override
  Future<void> deleteGarment(String garmentId, List<String> imageUrls) async {
    if (garmentId.isEmpty) {
      throw ArgumentError("Garment ID cannot be empty for deletion");
    }
    WriteBatch batch = _firestore.batch();
    DocumentReference garmentRef = _firestore
        .collection(garmentsCollection)
        .doc(garmentId);
    batch.delete(garmentRef);

    // TODO: Eliminar referencias a esta prenda en otros lugares
    //(como prendas favoritas de otros usuarios)

    List<Future<void>> deleteImageFutures = [];
    for (String imageUrl in imageUrls) {
      if (imageUrl.isNotEmpty) {
        try {
          Reference imageRef = _storage.refFromURL(imageUrl);
          deleteImageFutures.add(imageRef.delete());

          print(
            "GarmentRepo: Preparado para eliminar imagen de Storage: $imageUrl (Ruta: ${imageRef.fullPath})",
          );
        } catch (e) {
          print(
            "GarmentRepo Warning - deleteGarment: Could not get ref for URL $imageUrl. Error: $e",
          );
        }
      }
    }

    try {
      if (deleteImageFutures.isNotEmpty) {
        await Future.wait(deleteImageFutures);
        print("GarmentRepo: Imágenes de Storage eliminadas exitosamente.");
      }

      await batch.commit();
      print(
        "GarmentRepo: Documento de prenda $garmentId eliminado de Firestore.",
        //TODO: Cambiar reglas en Storage
      );
    } catch (e) {
      print("GarmentRepo Error - deleteGarment: $e");
      // ¿que hacer si algo falla?
      throw Exception("Failed to delete garment completely. Error: $e");
    }
  }

  @override
  Future<GarmentModel?> getGarmentById(String garmentId) async {
    try {
      final docSnapshot =
          await _firestore.collection(garmentsCollection).doc(garmentId).get();
      if (docSnapshot.exists) {
        return GarmentModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print("GarmentRepo Error - getGarmentById: $e");
      throw Exception("Failed to get garment from Firestore.");
    }
  }

  @override
  Future<void> updateGarmentData(
    String garmentId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    try {
      await _firestore
          .collection(garmentsCollection)
          .doc(garmentId)
          .update(dataToUpdate);
    } catch (e) {
      print("GarmentRepo Error - updateGarmentData: $e");
      throw Exception("Failed to update garment.");
    }
  }

  @override
  Future<List<String>> uploadGarmentImages({
    required String userId,
    required String garmentId,
    required List<XFile> imageFiles,
  }) async {
    if (imageFiles.isEmpty) return [];
    List<String> downloadUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final xFile = imageFiles[i];
        final String fileName =
            'garment_images/$userId/$garmentId/image_${_uuid.v4()}${xFile.mimeType?.replaceAll("image/", ".") ?? ".jpg"}';
        final Reference storageRef = _storage.ref().child(fileName);
        final UploadTask uploadTask;

        if (kIsWeb) {
          final Uint8List bytes = await xFile.readAsBytes();
          uploadTask = storageRef.putData(
            bytes,
            SettableMetadata(contentType: xFile.mimeType ?? 'image/jpeg'),
          );
        } else {
          uploadTask = storageRef.putFile(
            File(xFile.path),
            SettableMetadata(contentType: xFile.mimeType ?? 'image/jpeg'),
          );
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        print(
          "GarmentRepo: Imagen subida ${i + 1}/${imageFiles.length}: $downloadUrl",
        );
      }
      return downloadUrls;
    } catch (e) {
      print("GarmentRepo Error - uploadGarmentImages: $e");
      // Si alguna imagen falla ¿devolver las que se subieron o lanzar excepcion?
      throw Exception("Failed to upload garment images.");
    }
  }
}
