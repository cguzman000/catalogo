import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_catalogo/producto.dart';
import 'package:flutter_catalogo/settings_service.dart';
import 'package:path_provider/path_provider.dart';

// Enum para definir si estamos gestionando categorías o proveedores.
enum AttributeType { category, provider }

class ManageAttributesScreen extends StatefulWidget {
  final AttributeType attributeType;

  const ManageAttributesScreen({super.key, required this.attributeType});

  @override
  State<ManageAttributesScreen> createState() => _ManageAttributesScreenState();
}

class _ManageAttributesScreenState extends State<ManageAttributesScreen> {
  bool _isLoading = true;
  List<Producto> _todosLosProductos = [];
  Map<String, int> _attributeUsage = {};
  final _settingsService = SettingsService();

  String get _title => widget.attributeType == AttributeType.category
      ? 'Gestionar Categorías'
      : 'Gestionar Proveedores';

  String get _attributeNameSingular =>
      widget.attributeType == AttributeType.category
      ? 'categoría'
      : 'proveedor';

  String get _defaultAttributeValue =>
      widget.attributeType == AttributeType.category
      ? 'SIN CATEGORÍA'
      : 'SIN PROVEEDOR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data_productos.json');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final List<dynamic> data = json.decode(jsonString);
          _todosLosProductos = data
              .map((json) => Producto.fromJson(json))
              .toList();
          _calculateUsage();
        }
      }
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateUsage() {
    final usage = <String, int>{};
    for (final producto in _todosLosProductos) {
      final key = widget.attributeType == AttributeType.category
          ? producto.categoria
          : producto.proveedor;
      if (key.trim().isNotEmpty) {
        usage[key] = (usage[key] ?? 0) + 1;
      }
    }
    _attributeUsage = usage;
  }

  Future<void> _handleDelete(String attributeName) async {
    final count = _attributeUsage[attributeName] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar $_attributeNameSingular'),
        content: Text(
          'Esta acción reasignará $count producto(s) de la $_attributeNameSingular "$attributeName" a "$_defaultAttributeValue".\n\n¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reasignar y Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // Reassign products
      _todosLosProductos = _todosLosProductos.map((p) {
        if (widget.attributeType == AttributeType.category &&
            p.categoria == attributeName) {
          return Producto(
            id: p.id,
            nombre: p.nombre,
            uxcj: p.uxcj,
            categoria: _defaultAttributeValue,
            precioCompra: p.precioCompra,
            proveedor: p.proveedor,
            precioVenta: p.precioVenta,
            precioOferta: p.precioOferta,
            condicion: p.condicion,
            imagen: p.imagen,
            activo: p.activo,
          );
        }
        if (widget.attributeType == AttributeType.provider &&
            p.proveedor == attributeName) {
          return Producto(
            id: p.id,
            nombre: p.nombre,
            uxcj: p.uxcj,
            categoria: p.categoria,
            proveedor: _defaultAttributeValue,
            precioCompra: p.precioCompra,
            precioVenta: p.precioVenta,
            precioOferta: p.precioOferta,
            condicion: p.condicion,
            imagen: p.imagen,
            activo: p.activo,
          );
        }
        return p;
      }).toList();

      // Save to file
      final file = await _getLocalFile();
      final data = _todosLosProductos.map((p) => p.toJson()).toList();
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(data));

      // Notify main screen to reload
      _settingsService.productDataVersion.value++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operación completada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("Error al eliminar atributo: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort attributes alphabetically for display
    final sortedKeys = _attributeUsage.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedKeys.isEmpty
          ? const Center(child: Text('No hay datos para mostrar.'))
          : ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final attributeName = sortedKeys[index];
                final count = _attributeUsage[attributeName] ?? 0;
                // Prevent deleting the "default" category itself
                final canDelete = attributeName != _defaultAttributeValue;

                return ListTile(
                  title: Text(attributeName),
                  subtitle: Text('$count producto(s)'),
                  trailing: canDelete
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _handleDelete(attributeName),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
