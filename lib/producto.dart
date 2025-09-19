import 'package:flutter/foundation.dart';

@immutable
class Producto {
  final int id;
  final String nombre;
  final int uxcj;
  final String categoria;
  final String proveedor;
  final double precioCompra;
  final double precioVenta;
  final double precioOferta;
  final String condicion;
  final String imagen;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.uxcj,
    required this.categoria,
    required this.proveedor,
    required this.precioCompra,
    required this.precioVenta,
    required this.precioOferta,
    required this.condicion,
    required this.imagen,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['Id'] ?? 0,
      nombre: json['Nombre'] ?? 'Sin nombre',
      uxcj: json['UxCj'] ?? 0,
      categoria: json['Categoria'] ?? 'Sin categoría',
      proveedor: json['Proveedor'] ?? 'Sin proveedor',
      precioCompra: (json['PrecioCompra'] as num? ?? 0).toDouble(),
      precioVenta: (json['PrecioVenta'] as num? ?? 0).toDouble(),
      precioOferta: (json['PrecioOferta'] as num? ?? 0).toDouble(),
      condicion: json['Condicion'] ?? '',
      imagen: json['Imagen'] ?? '',
      activo: json['Activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Nombre': nombre,
      'UxCj': uxcj,
      'Categoria': categoria,
      'Proveedor': proveedor,
      'PrecioCompra': precioCompra,
      'PrecioVenta': precioVenta,
      'PrecioOferta': precioOferta,
      'Condicion': condicion,
      'Imagen': imagen,
      'Activo': activo,
    };
  }
}
