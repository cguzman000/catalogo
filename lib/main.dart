import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Flow;
import 'package:flutter_catalogo/producto.dart';
import 'package:flutter_catalogo/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_catalogo/common/app_footer.dart';
import 'package:flutter_catalogo/common/app_drawer.dart';
import 'package:flutter_catalogo/common/custom_app_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_catalogo/edit_product.dart'; // Ahora contiene ProductFormScreen
import 'package:flutter_catalogo/product_list_item.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Opciones para ordenar la lista de productos.
enum SortOption { proveedor, nombre, categoria }

void main() async {
  // Ensure that plugin services are initialized so that `path_provider`
  // and `shared_preferences` can be used before `runApp()`.
  WidgetsFlutterBinding.ensureInitialized();
  // Load services in parallel for faster startup.
  await SettingsService().loadSettings();
  runApp(const CatalogApp());
}

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Producto> _todosLosProductos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoading = true;
  String? _categoriaSeleccionada;
  List<String> _categorias = [];
  String? _proveedorSeleccionado;
  List<String> _proveedores = [];
  final _settingsService = SettingsService();
  final _searchController = TextEditingController();
  SortOption _sortOption = SortOption.proveedor;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _settingsService.productDataVersion.addListener(_cargarDatos);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filtrarProductos();
      });
    });
    // Imprime la ruta del archivo para depuración.
    // Puedes verificar el contenido de este archivo en el emulador/dispositivo.
    _getLocalFile().then(
      (file) => debugPrint('Ruta del archivo JSON: ${file.path}'),
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _settingsService.productDataVersion.removeListener(_cargarDatos);
    _searchController.dispose();
    super.dispose();
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data_productos.json');
  }

  Future<void> _guardarProductosEnJson() async {
    try {
      final file = await _getLocalFile();
      final data = _todosLosProductos.map((p) => p.toJson()).toList();
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(data));
    } catch (e) {
      debugPrint("Error al guardar productos: $e");
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final file = await _getLocalFile();
      String jsonString;

      // Intenta cargar desde el archivo local.
      if (await file.exists() &&
          (await file.readAsString()).trim().isNotEmpty) {
        final content = await file.readAsString();
        jsonString = content;
        debugPrint("Productos cargados desde el archivo local.");
      } else {
        // Si el archivo local no existe o está vacío, carga desde los assets.
        debugPrint(
          "Cargando productos desde assets/productos.json (primera vez o reseteo).",
        );
        jsonString = await rootBundle.loadString('assets/productos.json');
        // Y lo guarda localmente para futuros inicios.
        await file.writeAsString(jsonString);
      }
      _parseAndSetState(jsonString);
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
      // Fallback a una lista vacía en caso de cualquier error.
      _parseAndSetState('[]');
    }
  }

  List<String> _generarListaUnica(String Function(Producto) getField) {
    final Set<String> itemsSet = _todosLosProductos.map(getField).toSet();
    final List<String> itemsList = itemsSet.toList();
    itemsList.sort();
    itemsList.insert(0, 'Todos');
    return itemsList;
  }

  void _parseAndSetState(String jsonString) {
    if (!mounted) return;
    final List<dynamic> data = json.decode(jsonString);
    _todosLosProductos = data.map((json) => Producto.fromJson(json)).toList();
    _categorias = _generarListaUnica((p) => p.categoria);
    _proveedores = _generarListaUnica((p) => p.proveedor);

    if (mounted) {
      setState(() {
        // Llama a _filtrarProductos para establecer la lista inicial con el orden por defecto.
        _filtrarProductos();
        _isLoading = false;
      });
    }
  }

  void _filtrarProductos() {
    // Esta función ahora solo calcula la lista filtrada.
    // El `setState` es llamado por los manejadores de eventos que la invocan.
    List<Producto> productosTemp = _todosLosProductos.where((producto) {
      final matchCategoria =
          _categoriaSeleccionada == null ||
          producto.categoria == _categoriaSeleccionada;

      final matchProveedor =
          _proveedorSeleccionado == null ||
          producto.proveedor == _proveedorSeleccionado;

      final matchSearch =
          _searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchCategoria && matchProveedor && matchSearch;
    }).toList();

    // Aplica el ordenamiento basado en la opción seleccionada.
    switch (_sortOption) {
      case SortOption.nombre:
        productosTemp.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case SortOption.categoria:
        productosTemp.sort((a, b) {
          int compare = a.categoria.compareTo(b.categoria);
          if (compare == 0) {
            return a.nombre.compareTo(b.nombre); // Orden secundario por nombre
          }
          return compare;
        });
        break;
      case SortOption.proveedor:
        //default:
        productosTemp.sort((a, b) {
          int compare = a.proveedor.compareTo(b.proveedor);
          if (compare == 0) {
            return a.nombre.compareTo(b.nombre); // Orden secundario por nombre
          }
          return compare;
        });
        break;
    }
    _productosFiltrados = productosTemp;
  }

  void _navegarYAgregarProducto() async {
    final nuevoProducto = await Navigator.push<Producto>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          // Pasamos la lista de categorías sin "Todos"
          categorias: _categorias.where((c) => c != 'Todos').toList(),
          proveedores: _proveedores.where((p) => p != 'Todos').toList(),
        ),
      ),
    );

    if (nuevoProducto != null && mounted) {
      setState(() {
        _todosLosProductos.add(nuevoProducto);

        // Si la categoría es nueva, actualiza la lista de categorías.
        _categorias = _generarListaUnica((p) => p.categoria);
        _proveedores = _generarListaUnica((p) => p.proveedor);

        // Vuelve a aplicar el filtro actual para que el nuevo producto aparezca si corresponde.
        _filtrarProductos();
      });
      await _guardarProductosEnJson();
    }
  }

  void _navegarYEditarProducto(Producto productoAEditar) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          producto: productoAEditar,
          categorias: _categorias.where((c) => c != 'Todos').toList(),
          proveedores: _proveedores.where((p) => p != 'Todos').toList(),
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result is Producto) {
      setState(() {
        final index = _todosLosProductos.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          _todosLosProductos[index] = result;
        }
        _categorias = _generarListaUnica((p) => p.categoria);
        _proveedores = _generarListaUnica((p) => p.proveedor);
        _filtrarProductos();
      });
    } else if (result == 'DELETE') {
      setState(() {
        _todosLosProductos.removeWhere((p) => p.id == productoAEditar.id);
        _categorias = _generarListaUnica((p) => p.categoria);
        _proveedores = _generarListaUnica((p) => p.proveedor);
        _filtrarProductos();
      });
    }
    await _guardarProductosEnJson();
  }

  Future<void> _generateAndPrintPdf() async {
    final productosImprimir = _productosFiltrados
        .where((p) => p.activo)
        .toList();
    final pdf = pw.Document();

    final settingsService = SettingsService();
    final companyName = settingsService.companyName.value;
    final contactInfo = settingsService.contact.value;
    final ivaFactor = 1 + (settingsService.iva.value / 100);
    final logoPath = settingsService.logoPath.value;
    // Cargar logo
    Uint8List? logoBytes;
    try {
      logoBytes = await _loadImageBytes(logoPath);
      // Fallback to default asset if local file fails but path is not default
    } catch (e) {
      debugPrint("Error al cargar el logo para el PDF: $e");
      logoBytes = null;
    }

    // Pre-cargar imágenes de productos
    final List<Uint8List?> imagenesBytes = await Future.wait(
      productosImprimir.map((p) async {
        try {
          return await _loadImageBytes(p.imagen);
        } catch (e) {
          debugPrint("Error al cargar imagen del producto ${p.nombre}: $e");
          return null;
        }
      }),
    );

    // --- PDF Styles ---
    const PdfColor primaryColor = PdfColor.fromInt(0xFFD32F2F);
    const PdfColor lightGreyColor = PdfColor.fromInt(0xFFEEEEEE);
    const PdfColor darkGreyColor = PdfColor.fromInt(0xFF616161);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(pw.MemoryImage(logoBytes)),
                    ),
                  if (logoBytes != null) pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      pw.Text(
                        'Catálogo de Productos',
                        style: pw.TextStyle(color: darkGreyColor, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(contactInfo, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: List.generate(productosImprimir.length, (i) {
                return _buildPdfGridItem(
                  productosImprimir[i],
                  imagenesBytes[i],
                  ivaFactor,
                  primaryColor,
                  lightGreyColor,
                );
              }),
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<Uint8List> _loadImageBytes(String path) async {
    if (path.startsWith('assets/')) {
      final ByteData data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } else {
      // It's a file path
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      throw Exception('Image file not found: $path');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const CustomAppBar(title: 'Catálogo de Productos'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todosLosProductos.isEmpty
          ? const Center(
              child: Text(
                'No hay productos disponibles.\nPresiona el botón + para agregar uno.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          isDense: true, // Hace el campo más compacto
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, // Reduce la altura
                            horizontal: 10.0,
                          ),
                          labelText: 'Buscar por nombre',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButton<SortOption>(
                              isExpanded: true,
                              hint: const Text('Ordenar por'),
                              value: _sortOption,
                              items: const [
                                DropdownMenuItem(
                                  value: SortOption.proveedor,
                                  child: Text(
                                    'Por Proveedor',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.nombre,
                                  child: Text(
                                    'Por Nombre',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.categoria,
                                  child: Text(
                                    'Por Categoría',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (SortOption? newValue) {
                                if (newValue == null) return;
                                setState(() {
                                  _sortOption = newValue;
                                  _filtrarProductos();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text('Categoría'),
                              value: _categoriaSeleccionada ?? 'Todos',
                              items: _categorias.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _categoriaSeleccionada = val == 'Todos'
                                      ? null
                                      : val;
                                  _filtrarProductos();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text('Proveedor'),
                              value: _proveedorSeleccionado ?? 'Todos',
                              items: _proveedores.map((prov) {
                                return DropdownMenuItem<String>(
                                  value: prov,
                                  child: Text(
                                    prov,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _proveedorSeleccionado = val == 'Todos'
                                      ? null
                                      : val;
                                  _filtrarProductos();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      return ProductListItem(
                        producto: _productosFiltrados[index],
                        onTap: () =>
                            _navegarYEditarProducto(_productosFiltrados[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_product',
            onPressed: _navegarYAgregarProducto,
            tooltip: 'Agregar Nuevo Producto',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'print_catalog',
            onPressed: _generateAndPrintPdf,
            tooltip: 'Imprimir Catálogo',
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

pw.Widget _buildPdfGridItem(
  Producto p,
  Uint8List? imgBytes,
  double ivaFactor,
  PdfColor primaryColor,
  PdfColor lightGreyColor,
) {
  final hasOffer = p.precioOferta > 0 && p.precioOferta < p.precioVenta;

  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: lightGreyColor, width: 1.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // --- Image Container ---
        pw.Container(
          height: 120,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: const pw.BorderRadius.vertical(
              top: pw.Radius.circular(6),
            ),
          ),
          child: imgBytes != null
              ? pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.contain)
              : pw.Center(
                  child: pw.Text(
                    'Sin imagen',
                    style: const pw.TextStyle(color: PdfColors.grey),
                  ),
                ),
        ),

        // --- Details Container ---
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // --- Product Name ---
                pw.Text(
                  p.nombre,
                  maxLines: 3,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),

                // --- Prices ---
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (hasOffer && p.condicion.trim().isNotEmpty)
                      pw.Text(
                        p.condicion,
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    if (hasOffer) pw.SizedBox(height: 2),
                    pw.Text(
                      '\$${(p.precioVenta * ivaFactor).toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        decoration: hasOffer
                            ? pw.TextDecoration.lineThrough
                            : null,
                        color: hasOffer ? PdfColors.grey600 : PdfColors.black,
                        fontSize: hasOffer ? 12 : 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (hasOffer)
                      pw.Text(
                        '\$${(p.precioOferta * ivaFactor).toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
