import 'package:flutter/material.dart';
import 'package:flutter_catalogo/settings_service.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    const textStyle = TextStyle(color: Colors.black54, fontSize: 12);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[200],
      child: AnimatedBuilder(
        animation: Listenable.merge([
          settingsService.companyName,
          settingsService.address,
          settingsService.contact,
        ]),
        builder: (context, child) {
          final companyName = settingsService.companyName.value;
          final address = settingsService.address.value;
          final contact = settingsService.contact.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© ${DateTime.now().year} $companyName. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
              if (address.isNotEmpty && contact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Dirección: $address - Fono: $contact',
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
