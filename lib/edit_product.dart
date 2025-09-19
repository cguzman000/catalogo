import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_catalogo/common/app_footer.dart';
import 'package:flutter_catalogo/common/upper_case_text_formatter.dart';
import 'package:flutter_catalogo/common/custom_app_bar.dart';
import 'package:flutter_catalogo/producto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_catalogo/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:math_expressions/math_expressions.dart';

class ProductFormScreen extends StatefulWidget {
  final Producto? producto;
  final List<String> categorias;
  final List<String> proveedores;

  const ProductFormScreen({
    super.key,
    this.producto,
    required this.categorias,
    required this.proveedores,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditMode;
  late TextEditingController _nombreController;
  late TextEditingController _uxcjController;
  late TextEditingController _precioVentaController;
  late TextEditingController _profitMarginController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioOfertaController;
  late TextEditingController _condicionController;
  late TextEditingController _imagenController;
  final _nuevaCategoriaController = TextEditingController();
  final _nuevoProveedorController = TextEditingController();
  final _precioCompraFocusNode = FocusNode();
  final _precioFocusNode = FocusNode();
  final _precioOfertaFocusNode = FocusNode();
  String? _categoriaSeleccionada;
  late List<String> _allCategorias;
  String? _proveedorSeleccionado;
  late List<String> _allProveedores;
  late bool _isActivo;
  bool _precioVentaConIva =
      true; // Por defecto, el precio se muestra y edita con IVA.
  bool _precioCompraConIva =
      true; // Por defecto, el precio de compra se muestra y edita con IVA.
  bool _precioOfertaConIva =
      true; // Por defecto, el precio de oferta se muestra y edita con IVA.
  final _settingsService = SettingsService();

  String? _suggestedPriceText;
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.producto != null;

    _precioCompraFocusNode.addListener(() {
      if (!_precioCompraFocusNode.hasFocus) {
        _evaluateAndUpdateController(_precioCompraController);
      }
    });
    _precioFocusNode.addListener(() {
      if (!_precioFocusNode.hasFocus) {
        _evaluateAndUpdateController(_precioVentaController);
      }
    });
    _precioOfertaFocusNode.addListener(() {
      if (!_precioOfertaFocusNode.hasFocus) {
        _evaluateAndUpdateController(_precioOfertaController);
      }
    });

    _profitMarginController = TextEditingController(
      text: _settingsService.profitMargin.value.toStringAsFixed(1),
    )..addListener(_updateSuggestedPrice);

    _nombreController = TextEditingController(
      text: widget.producto?.nombre ?? '',
    );
    _uxcjController = TextEditingController(
      text: widget.producto?.uxcj == null || widget.producto?.uxcj == 0
          ? ''
          : widget.producto!.uxcj.toString(),
    );
    final ivaFactor = 1 + (_settingsService.iva.value / 100);

    // En modo edición, mostramos el precio con IVA por defecto.
    // En modo creación, también para consistencia.
    _precioVentaController = TextEditingController(
      text: _isEditMode
          ? (widget.producto!.precioVenta * ivaFactor).toStringAsFixed(2)
          : '',
    );
    _precioCompraController = TextEditingController(
      text: _isEditMode && widget.producto!.precioCompra > 0
          ? (widget.producto!.precioCompra * ivaFactor).toStringAsFixed(2)
          : '',
    )..addListener(_updateSuggestedPrice);
    _precioOfertaController = TextEditingController(
      text: _isEditMode
          ? (widget.producto!.precioOferta * ivaFactor).toStringAsFixed(2)
          : '',
    );
    _condicionController = TextEditingController(
      text: widget.producto?.condicion ?? '',
    );
    _imagenController = TextEditingController(
      text: widget.producto?.imagen ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateSuggestedPrice(),
    );

    _isActivo = widget.producto?.activo ?? true;

    // Se usa un Set para eliminar duplicados de la lista de categorías y se asegura que la categoría actual del producto esté presente.
    _allCategorias = {
      'Nueva Categoría',
      ...widget.categorias,
      if (_isEditMode) widget.producto!.categoria,
    }.toList();
    _allCategorias.sort((a, b) {
      if (a == 'Nueva Categoría') return -1;
      if (b == 'Nueva Categoría') return 1;
      return a.compareTo(b);
    });
    if (_isEditMode) {
      _categoriaSeleccionada = widget.producto!.categoria;
    }

    // Se usa un Set para eliminar duplicados de la lista de proveedores y se asegura que el proveedor actual del producto esté presente.
    _allProveedores = {
      'Nuevo Proveedor',
      ...widget.proveedores,
      if (_isEditMode) widget.producto!.proveedor,
    }.toList();
    _allProveedores.sort((a, b) {
      if (a == 'Nuevo Proveedor') return -1;
      if (b == 'Nuevo Proveedor') return 1;
      return a.compareTo(b);
    });
    if (_isEditMode) {
      _proveedorSeleccionado = widget.producto!.proveedor;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _uxcjController.dispose();
    _precioVentaController.dispose();
    _precioCompraController.removeListener(_updateSuggestedPrice);
    _precioCompraController.dispose();
    _profitMarginController.removeListener(_updateSuggestedPrice);
    _profitMarginController.dispose();
    _precioOfertaController.dispose();
    _condicionController.dispose();
    _imagenController.dispose();
    _nuevaCategoriaController.dispose();
    _nuevoProveedorController.dispose();
    _precioCompraFocusNode.dispose();
    _precioFocusNode.dispose();
    _precioOfertaFocusNode.dispose();
    super.dispose();
  }

  void _selectImage() async {
    // 1. Pick the file, ensuring we get the data for cloud files on Android.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Important for cloud files
    );

    if (result == null || result.files.isEmpty) {
      // User canceled the picker
      return;
    }

    final platformFile = result.files.single;
    final fileName = platformFile.name;

    // 2. Get the app's document directory
    final appDir = await getApplicationDocumentsDirectory();
    final localImagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await localImagesDir.exists()) {
      await localImagesDir.create(recursive: true);
    }

    final newFilePath = p.join(localImagesDir.path, fileName);
    final newFile = File(newFilePath);

    // 3. Copy the file or write its bytes to the local directory
    if (platformFile.bytes != null) {
      // If bytes are available (e.g., from cloud), write them.
      await newFile.writeAsBytes(platformFile.bytes!);
    } else if (platformFile.path != null) {
      // If a path is available, it's a local file we can copy.
      await File(platformFile.path!).copy(newFilePath);
    } else {
      // Handle the case where we can't get the file data.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el archivo de imagen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 4. Update the controller with the path to the new local file.
    if (mounted) {
      setState(() {
        _imagenController.text = newFilePath;
      });
    }
  }

  Future<void> _onDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted && _isEditMode) {
      // Devuelve un valor especial para indicar la eliminación
      Navigator.pop(context, 'DELETE');
    }
  }

  void _handlePrecioVentaConIvaChange(bool? newValue) {
    if (newValue == null) return;

    final currentValue = double.tryParse(_precioVentaController.text) ?? 0.0;
    if (currentValue == 0) {
      setState(() {
        _precioVentaConIva = newValue;
      });
      return;
    }

    final ivaFactor = 1 + (_settingsService.iva.value / 100);
    double newPrice;

    if (newValue == true && _precioVentaConIva == false) {
      // Convertir de Neto a Bruto (con IVA)
      newPrice = currentValue * ivaFactor;
    } else if (newValue == false && _precioVentaConIva == true) {
      // Convertir de Bruto (con IVA) a Neto
      newPrice = currentValue / ivaFactor;
    } else {
      newPrice = currentValue;
    }

    setState(() {
      _precioVentaConIva = newValue;
      _precioVentaController.text = newPrice.toStringAsFixed(2);
    });
  }

  void _updateSuggestedPrice() {
    final purchasePriceString = _precioCompraController.text.trim().replaceAll(
      ',',
      '.',
    );
    final marginString = _profitMarginController.text.trim().replaceAll(
      ',',
      '.',
    );

    final double purchasePrice = double.tryParse(purchasePriceString) ?? 0.0;
    final double margin = double.tryParse(marginString) ?? 0.0;

    if (purchasePrice <= 0 || margin < 0) {
      if (_suggestedPriceText != null) {
        if (mounted) {
          setState(() {
            _suggestedPriceText = null;
          });
        }
      }
      return;
    }

    final ivaFactor = 1 + (_settingsService.iva.value / 100);

    // Get net purchase price
    final double purchasePriceNet = _precioCompraConIva
        ? (purchasePrice / ivaFactor)
        : purchasePrice;

    // Calculate suggested prices
    final double suggestedNetPrice = purchasePriceNet / (1 - (margin / 100));
    final double suggestedGrossPrice = suggestedNetPrice * ivaFactor;

    if (mounted) {
      setState(() {
        _suggestedPriceText =
            'Sugerido: \$${suggestedGrossPrice.toStringAsFixed(0)} (Neto \$${suggestedNetPrice.toStringAsFixed(2)})';
      });
    }
  }

  void _handlePrecioCompraConIvaChange(bool? newValue) {
    if (newValue == null) return;

    final currentValue = double.tryParse(_precioCompraController.text) ?? 0.0;
    if (currentValue == 0) {
      setState(() {
        _precioCompraConIva = newValue;
      });
      return;
    }

    final ivaFactor = 1 + (_settingsService.iva.value / 100);
    double newPrice;

    if (newValue == true && _precioCompraConIva == false) {
      // Convertir de Neto a Bruto (con IVA)
      newPrice = currentValue * ivaFactor;
    } else if (newValue == false && _precioCompraConIva == true) {
      // Convertir de Bruto (con IVA) a Neto
      newPrice = currentValue / ivaFactor;
    } else {
      newPrice = currentValue;
    }

    setState(() {
      _precioCompraConIva = newValue;
      _precioCompraController.text = newPrice.toStringAsFixed(2);
    });
    _updateSuggestedPrice();
  }

  void _handlePrecioOfertaConIvaChange(bool? newValue) {
    if (newValue == null) return;

    final currentValue = double.tryParse(_precioOfertaController.text) ?? 0.0;
    if (currentValue == 0) {
      setState(() {
        _precioOfertaConIva = newValue;
      });
      return;
    }

    final ivaFactor = 1 + (_settingsService.iva.value / 100);
    double newPrice;

    if (newValue == true && _precioOfertaConIva == false) {
      // Convertir de Neto a Bruto (con IVA)
      newPrice = currentValue * ivaFactor;
    } else if (newValue == false && _precioOfertaConIva == true) {
      // Convertir de Bruto (con IVA) a Neto
      newPrice = currentValue / ivaFactor;
    } else {
      newPrice = currentValue;
    }

    setState(() {
      _precioOfertaConIva = newValue;
      _precioOfertaController.text = newPrice.toStringAsFixed(2);
    });
  }

  void _evaluateAndUpdateController(TextEditingController controller) {
    String expression = controller.text.trim().replaceAll(',', '.');
    if (expression.isEmpty) return;

    // Check if it's just a number, no need to evaluate.
    if (double.tryParse(expression) != null &&
        !expression.contains(RegExp(r'[\+\-\*\/]'))) {
      return;
    }

    try {
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Update controller. This will reflect in the UI.
      controller.text = eval.toStringAsFixed(2);
    } catch (e) {
      debugPrint('Could not evaluate expression: "$expression". Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expresión matemática no válida: "$expression"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onSave() {
    // Ensure expressions are evaluated before saving, in case a field still has focus.
    _evaluateAndUpdateController(_precioCompraController);
    _evaluateAndUpdateController(_precioVentaController);
    _evaluateAndUpdateController(_precioOfertaController);

    if (_formKey.currentState!.validate()) {
      final precioOfertaIngresado =
          double.tryParse(_precioOfertaController.text) ?? 0.0;
      final condicion = _condicionController.text.trim();

      if (precioOfertaIngresado > 0 && condicion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Si hay un precio de oferta, debe especificar una condición.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (condicion.isNotEmpty && precioOfertaIngresado <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Si hay una condición de oferta, debe especificar un precio de oferta.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String categoria;
      if (_categoriaSeleccionada == 'Nueva Categoría') {
        categoria = _nuevaCategoriaController.text.toUpperCase();
      } else {
        categoria = _categoriaSeleccionada!;
      }

      final String proveedor;
      if (_proveedorSeleccionado == 'Nuevo Proveedor') {
        proveedor = _nuevoProveedorController.text.toUpperCase();
      } else {
        proveedor = _proveedorSeleccionado!;
      }

      final double precioIngresado =
          double.tryParse(_precioVentaController.text) ?? 0.0;
      final double precioCompraIngresado =
          double.tryParse(_precioCompraController.text) ?? 0.0;
      final ivaFactor = 1 + (_settingsService.iva.value / 100);

      final double precioFinal = _precioVentaConIva
          ? (precioIngresado / ivaFactor)
          : precioIngresado;

      final double precioCompraFinal = _precioCompraConIva
          ? (precioCompraIngresado / ivaFactor)
          : precioCompraIngresado;

      final double precioOfertaFinal = _precioOfertaConIva
          ? (precioOfertaIngresado / ivaFactor)
          : precioOfertaIngresado;

      if (precioOfertaFinal > 0 && precioOfertaFinal >= precioFinal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El precio de oferta debe ser menor que el precio normal.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String condicionFinal = _condicionController.text.trim();
      if (condicionFinal.isNotEmpty) {
        condicionFinal =
            condicionFinal[0].toUpperCase() +
            (condicionFinal.length > 1 ? condicionFinal.substring(1) : '');
      }

      final productoResultante = Producto(
        id: widget.producto?.id ?? DateTime.now().millisecondsSinceEpoch,
        nombre: _nombreController.text,
        uxcj: int.tryParse(_uxcjController.text) ?? widget.producto?.uxcj ?? 1,
        categoria: categoria,
        proveedor: proveedor,
        precioCompra: precioCompraFinal,
        precioVenta: precioFinal,
        precioOferta: precioOfertaFinal,
        condicion: condicionFinal,
        imagen: _imagenController.text,
        activo: _isActivo,
      );
      Navigator.pop(context, productoResultante);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditMode ? 'Editar Producto' : 'Nuevo Producto',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Básica',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _uxcjController,
                      decoration: const InputDecoration(
                        labelText: 'Unidades por Caja (UxCj) (opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido o déjelo vacío';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormField<String>(
                      validator: (value) => _categoriaSeleccionada == null
                          ? 'Por favor seleccione una categoría'
                          : null,
                      builder: (FormFieldState<String> state) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            errorText: state.errorText,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          isEmpty: _categoriaSeleccionada == null,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _categoriaSeleccionada,
                              //hint: const Text('Seleccione una categoría'),
                              isDense: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _categoriaSeleccionada = newValue;
                                });
                                state.didChange(newValue);
                              },
                              items: _allCategorias
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_categoriaSeleccionada == 'Nueva Categoría')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: _nuevaCategoriaController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Nueva Categoría',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (_categoriaSeleccionada == 'Nueva Categoría' &&
                                (value == null || value.isEmpty)) {
                              return 'Por favor ingrese un nombre para la nueva categoría';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    FormField<String>(
                      validator: (value) => _proveedorSeleccionado == null
                          ? 'Por favor seleccione un proveedor'
                          : null,
                      builder: (FormFieldState<String> state) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Proveedor',
                            errorText: state.errorText,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          isEmpty: _proveedorSeleccionado == null,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _proveedorSeleccionado,
                              //hint: const Text('Seleccione un proveedor'),
                              isDense: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _proveedorSeleccionado = newValue;
                                });
                                state.didChange(newValue);
                              },
                              items: _allProveedores
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_proveedorSeleccionado == 'Nuevo Proveedor')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: _nuevoProveedorController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Nuevo Proveedor',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (_proveedorSeleccionado == 'Nuevo Proveedor' &&
                                (value == null || value.isEmpty)) {
                              return 'Por favor ingrese un nombre para el nuevo proveedor';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Producto Activo',
                          style: TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: _isActivo,
                          onChanged: (bool value) {
                            setState(() {
                              _isActivo = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precios y Ofertas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioCompraController,
                            focusNode: _precioCompraFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Precio Compra (opcional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _handlePrecioCompraConIvaChange(
                            !_precioCompraConIva,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _precioCompraConIva,
                                onChanged: _handlePrecioCompraConIvaChange,
                              ),
                              const Text('Inc. IVA'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _profitMarginController,
                      decoration: const InputDecoration(
                        labelText: '% Utilidad',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value.replaceAll(',', '.')) ==
                                null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioVentaController,
                            focusNode: _precioFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Precio Venta',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  double.tryParse(value) == null) {
                                return 'Por favor ingrese un precio válido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _handlePrecioVentaConIvaChange(
                            !_precioVentaConIva,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _precioVentaConIva,
                                onChanged: _handlePrecioVentaConIvaChange,
                              ),
                              const Text('Inc. IVA'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_suggestedPriceText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Text(
                          _suggestedPriceText!,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioOfertaController,
                            focusNode: _precioOfertaFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Precio Oferta (opcional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _handlePrecioOfertaConIvaChange(
                            !_precioOfertaConIva,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _precioOfertaConIva,
                                onChanged: _handlePrecioOfertaConIvaChange,
                              ),
                              const Text('Inc. IVA'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _condicionController,
                      decoration: const InputDecoration(
                        labelText: 'Condición Oferta (opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imagen del Producto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _imagenController,
                      decoration: const InputDecoration(
                        labelText: 'Ruta de Imagen (opcional)',
                        hintText:
                            'assets/productos_imagenes/MARCA/PRODUCTO.png',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _selectImage,
                          child: const Text("Seleccionar"),
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _imagenController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) {
                              return const SizedBox(
                                width: 80,
                                height: 80,
                                child: Center(child: Text('Sin imagen')),
                              );
                            }

                            Widget imageWidget;
                            if (value.text.startsWith('assets/')) {
                              imageWidget = Image.asset(
                                value.text,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Text('Vista previa no disponible'),
                                    ),
                              );
                            } else {
                              imageWidget = Image.file(
                                File(value.text),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Text('Vista previa no disponible'),
                                    ),
                              );
                            }

                            return SizedBox(
                              width: 80,
                              height: 80,
                              child: imageWidget,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: _isEditMode
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (_isEditMode)
                  ElevatedButton.icon(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.save),
                  label: Text(_isEditMode ? 'Actualizar' : 'Guardar'),
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
