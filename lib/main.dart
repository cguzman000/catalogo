import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Flow;
import 'package:flutter_catalogo/producto.dart';
import 'package:flutter_catalogo/settings_service.dart';
import 'package:flutter_catalogo/common/app_footer.dart';
import 'package:flutter_catalogo/common/app_drawer.dart';
import 'package:flutter_catalogo/common/custom_app_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_catalogo/common/animated_list_item.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_catalogo/edit_product.dart';
import 'package:flutter_catalogo/product_list_item.dart';

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
  bool _isAscending = true; // true para ascendente, false para descendente
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
        productosTemp.sort(
          (a, b) => _isAscending
              ? a.nombre.compareTo(b.nombre)
              : b.nombre.compareTo(a.nombre),
        );
        break;
      case SortOption.categoria:
        productosTemp.sort((a, b) {
          int compare = a.categoria.compareTo(b.categoria);
          if (compare == 0) {
            compare = a.nombre.compareTo(b.nombre); // Orden secundario
          }
          return _isAscending ? compare : -compare;
        });
        break;
      case SortOption.proveedor:
        //default:
        productosTemp.sort((a, b) {
          int compare = a.proveedor.compareTo(b.proveedor);
          if (compare == 0) {
            compare = a.nombre.compareTo(b.nombre); // Orden secundario
          }
          return _isAscending ? compare : -compare;
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

  String? _getHeaderTextForIndex(int index) {
    // No hay encabezados si no se ordena por categoría o proveedor.
    if (_sortOption != SortOption.categoria &&
        _sortOption != SortOption.proveedor) {
      return null;
    }

    final currentProduct = _productosFiltrados[index];

    // Siempre muestra el encabezado para el primer elemento de la lista.
    if (index == 0) {
      return _sortOption == SortOption.categoria
          ? currentProduct.categoria
          : currentProduct.proveedor;
    }

    final previousProduct = _productosFiltrados[index - 1];

    // Muestra el encabezado si el atributo de agrupación cambia.
    if (_sortOption == SortOption.categoria) {
      if (currentProduct.categoria != previousProduct.categoria) {
        return currentProduct.categoria;
      }
    } else if (_sortOption == SortOption.proveedor) {
      if (currentProduct.proveedor != previousProduct.proveedor) {
        return currentProduct.proveedor;
      }
    }

    // Si no, no se necesita un nuevo encabezado.
    return null;
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
                          IconButton(
                            icon: Icon(
                              _isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            tooltip: 'Cambiar Dirección de Orden',
                            onPressed: () {
                              setState(() {
                                _isAscending = !_isAscending;
                                _filtrarProductos();
                              });
                            },
                          ),
                          Expanded(
                            flex: 2, // Darle más espacio al primer dropdown
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<SortOption>(
                                isExpanded: true,
                                hint: const Text('Ordenar por'),
                                value: _sortOption,
                                items: const [
                                  DropdownMenuItem(
                                    value: SortOption.proveedor,
                                    child: Text('Proveedor'),
                                  ),
                                  DropdownMenuItem(
                                    value: SortOption.nombre,
                                    child: Text('Nombre'),
                                  ),
                                  DropdownMenuItem(
                                    value: SortOption.categoria,
                                    child: Text('Categoría'),
                                  ),
                                ],
                                onChanged: (SortOption? newValue) {
                                  if (newValue == null) return;
                                  setState(() {
                                    _sortOption = newValue;
                                    _filtrarProductos();
                                  });
                                },
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                itemHeight: 48,
                              ),
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
                    itemCount:
                        _productosFiltrados.length, // Un item por producto
                    itemBuilder: (context, index) {
                      final product = _productosFiltrados[index];
                      final headerText = _getHeaderTextForIndex(index);

                      final productItem = ProductListItem(
                        producto: product,
                        onTap: () => _navegarYEditarProducto(product),
                      );

                      if (headerText != null) {
                        return AnimatedListItem(
                          index: index,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _GroupHeader(title: headerText),
                              productItem,
                            ],
                          ),
                        );
                      }

                      return AnimatedListItem(index: index, child: productItem);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_product',
        onPressed: _navegarYAgregarProducto,
        tooltip: 'Agregar Nuevo Producto',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      //BARRA DE TITULOS POR CATEGORIA O PROVEEDOR
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade300, width: 3),
        ),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
