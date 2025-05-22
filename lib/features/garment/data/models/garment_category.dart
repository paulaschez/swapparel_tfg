enum GarmentCategory {
  tshirt,
  shirt,
  pants,
  shoes,
  dress,
  jacket,
  sweater,
  coat,
  accessory,
  other,
}

extension GarmentCategoryExtension on GarmentCategory {
  String get displayName {
    switch (this) {
      case GarmentCategory.shirt:
        return 'Camisa';
      case GarmentCategory.pants:
        return 'Pantalones';
      case GarmentCategory.shoes:
        return 'Calzado';
      case GarmentCategory.accessory:
        return 'Accesorio';
      case GarmentCategory.dress:
        return 'Vestido';
      case GarmentCategory.tshirt:
        return 'Camiseta';
      case GarmentCategory.jacket:
        return 'Chaqueta';
      case GarmentCategory.sweater:
        return 'Jersey';
      case GarmentCategory.coat:
        return 'Abrigo';
      case GarmentCategory.other:
        return 'Otro';
    }
  }
}
