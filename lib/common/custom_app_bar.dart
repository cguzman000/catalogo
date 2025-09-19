import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_catalogo/settings_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  Widget _buildLogo(String logoPath) {
    // The AppBar logo is typically the full logo (imagotipo).
    if (logoPath.startsWith('assets/')) {
      return Image.asset(
        logoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported),
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
            );
          }
          // Fallback to a placeholder if the file doesn't exist.
          return const Icon(Icons.image_not_supported, size: 60);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    return AppBar(
      toolbarHeight: 100,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: settingsService.logoPath,
                builder: (context, logoPath, child) => SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipOval(child: _buildLogo(logoPath)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: settingsService.companyName,
                  builder: (context, companyName, child) {
                    return Text(
                      companyName.replaceAll(' Ltda.', '\nLtda.'),
                      style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
