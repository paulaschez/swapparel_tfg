enum GarmentSize {
  xs,
  s,
  m,
  l,
  xl,
  xxl,
  unica,
  thirtysix,
  thirtyeight,
  fourty,
  fourtytwo,
  other,
}

extension GarmentSizeExtension on GarmentSize {
  String get displayName {
    switch (this) {
      case GarmentSize.other:
        return 'Otro';
      case GarmentSize.xs:
        return 'XS';
      case GarmentSize.s:
        return 'S';
      case GarmentSize.m:
        return 'M';
      case GarmentSize.l:
        return 'L';
      case GarmentSize.xl:
        return 'XL';
      case GarmentSize.xxl:
        return 'XXL';
      case GarmentSize.unica:
        return 'Única';
      case GarmentSize.thirtysix:
        return '36';
      case GarmentSize.thirtyeight:
        return '38';
      case GarmentSize.fourty:
        return '40';
      case GarmentSize.fourtytwo:
        return '42';
    }
  }
}
