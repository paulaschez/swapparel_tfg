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
  Future<void> deleteSpecificGarmentImages(List<String> imageUrlsToDelete);
  Future<void> updateGarmentAvailability(String garmentId, bool isAvailable);

  Future<List<GarmentModel>> getMultipleGarmentsByIds(List<String> garmentIds);
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
      await batch.commit();

      if (deleteImageFutures.isNotEmpty) {
        await Future.wait(deleteImageFutures);
        print("GarmentRepo: Imágenes de Storage eliminadas exitosamente.");
      }
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

  @override
  Future<void> deleteSpecificGarmentImages(
    List<String> imageUrlsToDelete,
  ) async {
    if (imageUrlsToDelete.isEmpty) {
      print("GarmentRepo: No images provided to deleteSpecificGarmentImages.");
      return;
    }

    List<Future<void>> deleteImageFutures = [];
    List<String> successfullyDeletedPaths = [];
    List<String> failedDeletionUrls = [];

    for (String imageUrl in imageUrlsToDelete) {
      if (imageUrl.isNotEmpty) {
        try {
          Reference imageRef = _storage.refFromURL(imageUrl);
          deleteImageFutures.add(
            imageRef
                .delete()
                .then((_) {
                  print(
                    "GarmentRepo: Imagen eliminada de Storage: ${imageRef.fullPath}",
                  );
                  successfullyDeletedPaths.add(imageRef.fullPath);
                })
                .catchError((error) {
                  print(
                    "GarmentRepo Warning - Failed to delete image (from future) $imageUrl (Path: ${imageRef.fullPath}). Error: $error",
                  );
                  failedDeletionUrls.add(imageUrl);
                }),
          );

          print(
            "GarmentRepo: Preparado para eliminar imagen de Storage: $imageUrl (Ruta: ${imageRef.fullPath})",
          );
        } catch (e) {
          print(
            "GarmentRepo Warning - deleteSpecificGarmentImages: Could not get ref for URL $imageUrl. Error: $e",
          );
          failedDeletionUrls.add(imageUrl);
        }
      }
    }

    if (deleteImageFutures.isNotEmpty) {
      try {
        await Future.wait(deleteImageFutures);
        print(
          "GarmentRepo:Proceso de eliminación de imágenes de Storage completado.",
        );
        if (failedDeletionUrls.isNotEmpty) {
          print(
            "GarmentRepo: Fallo al eliminar las siguientes URLs de Storage: $failedDeletionUrls",
          );
          // Podrías querer lanzar una excepción aquí si CUALQUIER imagen falló,
          // o simplemente loguearlo y continuar.
          // throw Exception("Algunas imágenes no pudieron ser eliminadas de Storage.");
        }
      } catch (e) {
        print(
          "GarmentRepo Error - deleteSpecificGarmentImages (Future.wait): $e",
        );
        throw Exception(
          "Error general durante la eliminación de imágenes de Storage.",
        );
      }
    } else if (imageUrlsToDelete.isNotEmpty &&
        failedDeletionUrls.length == imageUrlsToDelete.length) {
      // Todas las URLs eran inválidas o fallaron al obtener la referencia
      throw Exception(
        "No se pudieron obtener referencias válidas para ninguna de las imágenes a eliminar.",
      );
    }
  }

  @override
  Future<void> updateGarmentAvailability(
    String garmentId,
    bool isAvailable,
  ) async {
    if (garmentId.isEmpty) {
      throw ArgumentError(
        "Garment ID cannot be empty when updating availability.",
      );
    }
    try {
      print(
        "GarmentRepo: Actualizando disponibilidad de $garmentId a $isAvailable",
      );
      await _firestore.collection(garmentsCollection).doc(garmentId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        "GarmentRepo: OK - Availability para $garmentId ahora es $isAvailable",
      );
    } catch (e) {
      print("GarmentRepo Error - updateGarmentAvailability en $garmentId: $e");
      throw Exception("Failed to update garment availability.");
    }
  }

  @override
  Future<List<GarmentModel>> getMultipleGarmentsByIds(
    List<String> garmentIds,
  ) async {
    if (garmentIds.isEmpty) {
      return []; // No hay IDs, no hay nada que buscar
    }

    List<GarmentModel> fetchedGarments = [];
    // Firestore limita las consultas 'IN' a un máximo de 30 valores (anteriormente 10).
    // Es más seguro usar el límite más restrictivo si no estás seguro de la versión o para
    // futuras compatibilidades, o simplemente dividir en lotes más pequeños.
    // El límite actual es 30 para 'in', 'not-in', y 'array-contains-any'.
    const int firestoreQueryLimit = 30;
    List<List<String>> idChunks = [];

    for (var i = 0; i < garmentIds.length; i += firestoreQueryLimit) {
      idChunks.add(
        garmentIds.sublist(
          i,
          i + firestoreQueryLimit > garmentIds.length
              ? garmentIds.length
              : i + firestoreQueryLimit,
        ),
      );
    }

    try {
      for (final chunk in idChunks) {
        if (chunk.isEmpty)
          continue; // Saltar chunks vacíos (no debería pasar con la lógica anterior)

        print("GarmentRepo: Fetching chunk of garments by IDs: $chunk");
        final QuerySnapshot querySnapshot =
            await _firestore
                .collection(garmentsCollection)
                .where(
                  FieldPath.documentId,
                  whereIn: chunk,
                ) // Busca documentos cuyo ID esté en la lista 'chunk'
                .get();

        for (var doc in querySnapshot.docs) {
          if (doc.exists && doc.data() != null) {
            fetchedGarments.add(
              GarmentModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ),
            );
          }
        }
      }
      print(
        "GarmentRepo: Fetched ${fetchedGarments.length} garments for ${garmentIds.length} IDs.",
      );
      return fetchedGarments;
    } catch (e) {
      print("GarmentRepo Error - getMultipleGarmentsByIds: $e");
      // Devuelve la lista de lo que se pudo obtener, o una lista vacía, o relanza la excepción.
      // Devolver lo obtenido parcialmente puede ser útil.
      // throw Exception("Failed to get some garments by IDs.");
      return fetchedGarments; // O return [] si prefieres fallar completamente.
    }
  }
}
