import 'package:flutter/material.dart';
import 'package:flutter_catalogo/settings_screen.dart';
import 'package:flutter_catalogo/main.dart';
import 'dart:io';
import 'package:flutter_catalogo/settings_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    // The settings service is loaded at app startup, so we don't need to do anything here.
    // ValueListenableBuilder will handle UI updates.
  }

  Widget _buildLogo(String logoPath) {
    if (logoPath.startsWith('assets/')) {
      return Image.asset(
        logoPath,
        fit: BoxFit.cover,
        height: 60,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.business, color: Colors.white, size: 60),
      );
    } else {
      final file = File(logoPath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              height: 60,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.business, color: Colors.white, size: 60),
            );
          }
          return const Icon(Icons.business, color: Colors.white, size: 60);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // The header is fixed and will not scroll.
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            accountName: ValueListenableBuilder<String>(
              valueListenable: _settingsService.companyName,
              builder: (context, companyName, child) => Text(
                companyName,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 18, // Adjusted for better fit
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountEmail: null, // No email to show
            currentAccountPicture: ValueListenableBuilder<String>(
              valueListenable: _settingsService.logoPath,
              builder: (context, logoPath, child) {
                // For the drawer, we prefer the icon-only version ('isotipo')
                // if the full logo ('imagotipo') is selected.
                final drawerLogoPath = (logoPath == 'assets/imagotipo.png')
                    ? 'assets/isotipo.png'
                    : logoPath;
                return CircleAvatar(
                  backgroundColor: Colors.white,
                  child: _buildLogo(drawerLogoPath),
                );
              },
            ),
            currentAccountPictureSize: const Size.square(64),
          ),
          // The list of items will scroll if there's not enough space.
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Catálogo de Productos'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    // Si ya estamos en MainScreen, no hacemos nada.
                    // Para una app más compleja, se usarían rutas nombradas.
                    if (ModalRoute.of(context)?.settings.name != '/') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context); // Cierra el drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ); // No need to reload, ValueNotifier handles it.
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
