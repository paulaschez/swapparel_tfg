import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ImagePickerUtils {
  final ImagePicker _picker = ImagePicker();


  Future<XFile?> pickImage(BuildContext context) async {
    bool isMobilePlatform =
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    ImageSource? imageSource;

    if (kIsWeb || !isMobilePlatform) {
      imageSource = ImageSource.gallery;
    } else {
      FocusScope.of(context).unfocus();
      imageSource = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Subir de la galería'),
                  onTap: () {
                    
                    Navigator.of(bc).pop(ImageSource.gallery);
                    print('Seleccionar de galería');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.of(bc).pop(ImageSource.camera);
                    print('Tomar foto');
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    if(imageSource != null){
      return _pickImage(imageSource);
    }

    return null;
  }

  // Metodo para manejar la seleccion / toma de fotos
  Future<XFile?> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {

        /* if(kIsWeb){
          final Uint8List imageBytes = await pickedFile.readAsBytes();

        } */
        return pickedFile;
      }
    } catch (e) {
      print("ImagePickerUtils Error - _pickImage: $e");
     
      //TODO: MANEJO DE ERRORES
    }
    return null;
  }
}
