import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_catalogo/producto.dart';
import 'package:flutter_catalogo/settings_service.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.producto,
    required this.onTap,
  });

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isActivo = producto.activo;
    final Color? textColor = isActivo ? null : Colors.grey.shade600;

    Widget imageWidget;
    final imagePath = producto.imagen;

    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('assets/')) {
        imageWidget = Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        );
      } else {
        imageWidget = Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        );
      }
    } else {
      imageWidget = const Icon(Icons.image_not_supported);
    }

    return InkWell(
      onTap: onTap,
      child: Card(
        color: isActivo ? Colors.white : Colors.grey.shade200,
        elevation: isActivo ? 1.0 : 0.0,
        margin: const EdgeInsets.all(5),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: isActivo ? 1.0 : 0.5,
                child: SizedBox(width: 80, height: 80, child: imageWidget),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Categoría: ${producto.categoria}',
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Proveedor: ${producto.proveedor}',
                      style: TextStyle(
                        color: textColor,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildPriceInfo(isActivo, textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(bool isActivo, Color? textColor) {
    final settingsService = SettingsService();
    final ivaFactor = 1 + (settingsService.iva.value / 100);
    final hasOffer =
        producto.precioOferta > 0 &&
        producto.precioOferta < producto.precioVenta;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            Text(
              '\$${(producto.precioVenta * ivaFactor).toStringAsFixed(0)} c/u',
              style: TextStyle(
                color: isActivo
                    ? (hasOffer ? Colors.grey.shade500 : Colors.blue)
                    : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '(Neto \$${producto.precioVenta.toStringAsFixed(2)})',
              style: TextStyle(
                color: isActivo
                    ? (hasOffer ? Colors.grey.shade700 : Colors.green)
                    : Colors.grey.shade700,
                fontSize: 10,
              ),
            ),
          ],
        ),
        if (hasOffer && producto.condicion.trim().isNotEmpty)
          Text(
            'Oferta: ${producto.condicion}',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isActivo ? Colors.red : Colors.grey.shade600,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (hasOffer)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Text(
                  '\$${(producto.precioOferta * ivaFactor).toStringAsFixed(0)} c/u',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isActivo ? Colors.red : Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '(Neto \$${producto.precioOferta.toStringAsFixed(2)})',
                  style: TextStyle(
                    color: isActivo
                        ? Colors.red.shade400
                        : Colors.grey.shade700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
