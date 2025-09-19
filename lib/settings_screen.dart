import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_catalogo/common/app_footer.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_catalogo/manage_attributes_screen.dart';
import 'package:flutter_catalogo/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreEmpresaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contactoController = TextEditingController();
  final _logoPathController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nombreEmpresaController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    _logoPathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    // Values are loaded from the SettingsService's notifiers.
    _nombreEmpresaController.text = _settingsService.companyName.value;
    _logoPathController.text = _settingsService.logoPath.value;
    _direccionController.text = _settingsService.address.value;
    _contactoController.text = _settingsService.contact.value;
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _settingsService.saveSettings(
        newCompanyName: _nombreEmpresaController.text,
        newLogoPath: _logoPathController.text,
        newAddress: _direccionController.text,
        newContact: _contactoController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar Configuración'),
          content: const Text(
            'Esto restaurará el nombre de la empresa, logo y otros datos a sus valores por defecto. ¿Continuar?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Restaurar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _settingsService.resetSettings();
      if (mounted) {
        _loadSettings(); // Reload controllers with default values
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La configuración ha sido restaurada.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> _editIva() async {
    final ivaController = TextEditingController(
      text: _settingsService.iva.value.toStringAsFixed(1),
    );
    final formKey = GlobalKey<FormState>();

    final newIva = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar IVA'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ivaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Porcentaje de IVA',
                suffixText: '%',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un valor';
                }
                // Reemplaza la coma por un punto para el parseo
                final number = double.tryParse(value.replaceAll(',', '.'));
                if (number == null || number < 0) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final value = double.tryParse(
                    ivaController.text.replaceAll(',', '.'),
                  );
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newIva != null) {
      await _settingsService.saveIva(newIva);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IVA actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editProfitMargin() async {
    final marginController = TextEditingController(
      text: _settingsService.profitMargin.value.toStringAsFixed(1),
    );
    final formKey = GlobalKey<FormState>();

    final newMargin = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Margen de Utilidad'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: marginController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Margen de Utilidad',
                suffixText: '%',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un valor';
                }
                final number = double.tryParse(value.replaceAll(',', '.'));
                if (number == null || number < 0) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final value = double.tryParse(
                    marginController.text.replaceAll(',', '.'),
                  );
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newMargin != null) {
      await _settingsService.saveProfitMargin(newMargin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Margen de utilidad actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resetProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar Productos'),
          content: const Text(
            'Esto restaurará la lista de productos a su estado original, usando los datos de la aplicación. Perderás los productos que hayas agregado o modificado. ¿Continuar?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Restaurar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _settingsService.resetProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los productos han sido restaurados.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<void> _selectLogo() async {
    final newPath = await _settingsService.selectAndCopyLogo();
    if (newPath != null && mounted) {
      setState(() {
        _logoPathController.text = newPath;
      });
    }
  }

  Widget _buildLogoPreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _logoPathController,
      builder: (context, value, child) {
        if (value.text.isEmpty) {
          return const Icon(Icons.image, size: 40, color: Colors.grey);
        }

        Widget imageWidget;
        if (value.text.startsWith('assets/')) {
          imageWidget = Image.asset(
            value.text,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error),
          );
        } else {
          imageWidget = Image.file(
            File(value.text),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error),
          );
        }
        return SizedBox(
          width: 40,
          height: 40,
          child: ClipOval(
            child: FittedBox(fit: BoxFit.cover, child: imageWidget),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Configuración de la Empresa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreEmpresaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Empresa',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Este campo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    onTap: _selectLogo,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    leading: _buildLogoPreview(),
                    title: const Text('Logo de la Empresa'),
                    subtitle: Text(
                      p.basename(_logoPathController.text),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.edit),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactoController,
                    decoration: const InputDecoration(
                      labelText: 'Contacto (Teléfono, Email, etc.)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Configuración de Impuestos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: _settingsService.iva,
                    builder: (context, ivaValue, child) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('IVA (${ivaValue.toStringAsFixed(1)}%)'),
                        trailing: const Icon(Icons.edit),
                        onTap: _editIva,
                      );
                    },
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Configuración de Negocio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: _settingsService.profitMargin,
                    builder: (context, marginValue, child) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Margen de Utilidad por Defecto (${marginValue.toStringAsFixed(1)}%)',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _editProfitMargin,
                      );
                    },
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Gestión de Datos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('Restaurar Productos'),
                    subtitle: const Text(
                      'Restaura la lista de productos a la versión original.',
                    ),
                    onTap: _resetProducts,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Gestionar Categorías'),
                    subtitle: const Text(
                      'Reasigna productos para eliminar categorías no deseadas.',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAttributesScreen(
                          attributeType: AttributeType.category,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Gestionar Proveedores'),
                    subtitle: const Text(
                      'Reasigna productos para eliminar proveedores no deseados.',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAttributesScreen(
                          attributeType: AttributeType.provider,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _resetSettings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restaurar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
