import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SettingsService {
  // Singleton para asegurar una única instancia del servicio
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Claves para SharedPreferences
  static const String _keyNombreEmpresa = 'settings_nombre_empresa';
  static const String _keyLogoPath = 'settings_logo_path';
  static const String _keyDireccion = 'settings_direccion';
  static const String _keyContacto = 'settings_contacto';

  // Notificadores de valor para una UI reactiva
  final ValueNotifier<String> companyName = ValueNotifier(
    'Insupan Guzmán Ltda.',
  );
  final ValueNotifier<String> logoPath = ValueNotifier(
    'assets/isotipo_insupan.png',
  );
  final ValueNotifier<String> address = ValueNotifier('');
  final ValueNotifier<String> contact = ValueNotifier('');

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    companyName.value =
        prefs.getString(_keyNombreEmpresa) ?? 'Insupan Guzmán Ltda.';
    logoPath.value =
        prefs.getString(_keyLogoPath) ?? 'assets/isotipo_insupan.png';
    address.value = prefs.getString(_keyDireccion) ?? '';
    contact.value = prefs.getString(_keyContacto) ?? '';
  }

  Future<void> saveSettings({
    required String newCompanyName,
    required String newLogoPath,
    required String newAddress,
    required String newContact,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNombreEmpresa, newCompanyName);
    await prefs.setString(_keyLogoPath, newLogoPath);
    await prefs.setString(_keyDireccion, newAddress);
    await prefs.setString(_keyContacto, newContact);

    // Actualiza los notificadores para disparar los cambios en la UI
    companyName.value = newCompanyName;
    logoPath.value = newLogoPath;
    address.value = newAddress;
    contact.value = newContact;
  }

  Future<String?> selectAndCopyLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result == null || result.files.single.path == null) return null;

    final pickedFile = File(result.files.single.path!);
    final fileName = p.basename(pickedFile.path);

    final appDir = await getApplicationDocumentsDirectory();
    final localImagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await localImagesDir.exists()) {
      await localImagesDir.create(recursive: true);
    }

    final newFile = await pickedFile.copy(
      p.join(localImagesDir.path, fileName),
    );
    return newFile.path;
  }
}
