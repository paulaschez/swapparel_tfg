class Validators {
  // Valida que un correo electrónico tenga un formato estándar.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, introduce tu email.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor, introduce un email válido.';
    }
    return null;
  }

  // Valida que la contraseña no esté vacía y tenga al menos 6 caracteres.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce la contraseña.';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  // Valida que dos contraseñas coincidan.
  static String? validateConfirmPassword(
    String? value,
    String passwordToMatch,
  ) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirma la contraseña.';
    }
    if (value != passwordToMatch) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // Validador genérico para campos que no pueden estar vacíos.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo "$fieldName" no puede estar vacío.';
    }
    return null;
  }

  // Valida que se haya seleccionado un valor en un Dropdown o campo similar.
  static String? validateDropdown(dynamic value, String fieldName) {
    if (value == null) {
      return 'Debes seleccionar una $fieldName.';
    }
    return null;
  }
}
