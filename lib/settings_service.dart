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
  static const String _keyIva = 'settings_iva';
  static const String _keyProfitMargin = 'settings_profit_margin';

  // Notificadores de valor para una UI reactiva
  final ValueNotifier<String> companyName = ValueNotifier('Ktalog');
  final ValueNotifier<String> logoPath = ValueNotifier(
    'assets/icon_ktalog.png',
  );
  final ValueNotifier<String> address = ValueNotifier('');
  final ValueNotifier<String> contact = ValueNotifier('');
  final ValueNotifier<double> iva = ValueNotifier(19.0);
  final ValueNotifier<double> profitMargin = ValueNotifier(30.0);

  // Notificador para refrescar la lista de productos en MainScreen
  final ValueNotifier<int> productDataVersion = ValueNotifier(0);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    companyName.value = prefs.getString(_keyNombreEmpresa) ?? 'Ktalog';
    logoPath.value = prefs.getString(_keyLogoPath) ?? 'assets/icon_ktalog.png';
    address.value = prefs.getString(_keyDireccion) ?? '';
    contact.value = prefs.getString(_keyContacto) ?? '';
    iva.value = prefs.getDouble(_keyIva) ?? 19.0;
    profitMargin.value = prefs.getDouble(_keyProfitMargin) ?? 30.0;
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

  Future<void> saveIva(double newIva) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyIva, newIva);
    // Actualiza el notificador para disparar los cambios en la UI
    iva.value = newIva;
  }

  Future<void> saveProfitMargin(double newMargin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyProfitMargin, newMargin);
    profitMargin.value = newMargin;
  }

  Future<String?> selectAndCopyLogo() async {
    // The withData: true argument is important to get the file bytes.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Ask the picker to load the file data into memory
    );

    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    final fileName = platformFile.name; // Use the original file name.

    final appDir = await getApplicationDocumentsDirectory();
    final localImagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await localImagesDir.exists()) {
      await localImagesDir.create(recursive: true);
    }

    final newFilePath = p.join(localImagesDir.path, fileName);
    final newFile = File(newFilePath);

    // If we have bytes, it means it's from the cloud or a source that doesn't provide a direct path.
    // We write the bytes directly.
    if (platformFile.bytes != null) {
      await newFile.writeAsBytes(platformFile.bytes!);
    } else if (platformFile.path != null) {
      // If we have a path, it's a local file that we can copy.
      await File(platformFile.path!).copy(newFilePath);
    } else {
      // No path and no bytes, we can't proceed.
      return null;
    }

    return newFile.path;
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all settings managed by this service
    await prefs.remove(_keyNombreEmpresa);
    await prefs.remove(_keyLogoPath);
    await prefs.remove(_keyDireccion);
    await prefs.remove(_keyContacto);
    await prefs.remove(_keyIva);
    await prefs.remove(_keyProfitMargin);

    // Reload settings to apply defaults, which will update the ValueNotifiers
    await loadSettings();
  }

  Future<void> resetProducts() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data_productos.json');
      if (await file.exists()) {
        await file.delete();
        productDataVersion.value++;
      }
    } catch (e) {
      debugPrint("Error al borrar los productos: $e");
    }
  }
}
