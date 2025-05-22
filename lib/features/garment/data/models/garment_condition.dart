enum GarmentCondition { nuevo, almostNew, good, used }

extension GarmentConditionExtension on GarmentCondition {
  String get displayName {
    switch (this) {
      case GarmentCondition.nuevo:
        return 'Nuevo con etiquetas';
      case GarmentCondition.almostNew:
        return 'Como nuevo';
      case GarmentCondition.good:
        return 'Buen estado';
      case GarmentCondition.used:
        return 'Usado con detalles';
    }
  }
}
