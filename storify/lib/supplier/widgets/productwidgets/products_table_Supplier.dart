import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

// Product model for the table
class ProductModel {
  final int productId;
  final String name;
  final String image;
  final double costPrice;
  final double sellPrice;
  final String categoryName;
  String status; // Changed to non-final to allow direct updates
  final int? quantity;
  final String? description;
  final double? priceSupplier;

  ProductModel({
    required this.productId,
    required this.name,
    required this.image,
    required this.costPrice,
    required this.sellPrice,
    required this.categoryName,
    required this.status,
    this.quantity,
    this.description,
    this.priceSupplier,
  });

  // Factory constructor to create a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Normalize status when creating model
    String normalizedStatus = json['status'] ?? 'notActive';

    // Ensure consistent status format
    if (normalizedStatus == "notActive") {
      normalizedStatus = "notActive";
    } else if (normalizedStatus == "active") {
      normalizedStatus = "Active";
    }

    print(
        '📊 Parsing product: ${json['name']} with status: ${json['status']} → normalized to: $normalizedStatus');

    return ProductModel(
      productId: json['productId'],
      name: json['name'],
      image: json['image'] ?? 'https://picsum.photos/200',
      costPrice: double.parse(json['costPrice'].toString()),
      sellPrice: double.parse(json['sellPrice'].toString()),
      categoryName: json['category']['categoryName'] ?? 'Unknown',
      status: normalizedStatus,
      quantity: json['quantity'],
      description: json['description'],
      priceSupplier: json['priceSupplier'] != null
          ? double.parse(json['priceSupplier'].toString())
          : null,
    );
  }
}

class ProductsTableSupplier extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Active, 2: Not Active
  final String searchQuery;

  const ProductsTableSupplier({
    super.key, // Make sure key is passed to super
    required this.selectedFilterIndex,
    required this.searchQuery,
  });

  @override
  // ignore: library_private_types_in_public_api
  ProductsTableSupplierState createState() => ProductsTableSupplierState();
}

class ProductsTableSupplierState extends State<ProductsTableSupplier> {
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  int? _supplierId;

  int _currentPage = 1;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _itemsPerPage = 5;

  // Controllers for the edit dialog
  TextEditingController _priceController = TextEditingController();
  bool _statusSwitch = false;

  @override
  void initState() {
    super.initState();
    _loadSupplierId().then((_) => _fetchProducts());
  }

  void refreshProducts() {
    print('Refreshing products table, clearing existing data...');

    setState(() {
      _allProducts = [];
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchProducts();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  // Load supplierId from SharedPreferences
  Future<void> _loadSupplierId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _supplierId = prefs.getInt('supplierId');
    });
    print('📦 Loaded supplierId for table: $_supplierId');
  }

  // Fetch products from the API with cache-busting
  Future<void> _fetchProducts() async {
    if (_supplierId == null) {
      print('⚠️ No supplierId found, cannot fetch products');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse(
          'https://finalproject-a5ls.onrender.com/supplierOrders/supplier/$_supplierId/products?t=$timestamp');

      print('🌐 Fetching products from: $url');

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Data received: ${data['products']?.length ?? 0} products');

        if (data['products'] != null && data['products'] is List) {
          List<ProductModel> products = [];

          for (var product in data['products']) {
            print(
                'Product ${product['name']} raw status: ${product['status']}');
            products.add(ProductModel.fromJson(product));
          }

          setState(() {
            _allProducts = products;
            _isLoading = false;
          });

          print('✅ Table updated with ${products.length} products');
        } else {
          print('⚠️ Invalid response format: ${response.body}');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print(
            '⚠️ Error fetching products: ${response.statusCode}, Body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ Exception fetching products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show combined edit dialog for price and status
  Future<void> _showEditDialog(ProductModel product) async {
    // Initialize price controller with current value or cost price
    _priceController.text =
        product.priceSupplier?.toString() ?? product.costPrice.toString();

    // Initialize status switch
    // _statusSwitch = product.status == "Active";
    print('🔍 Current product status before dialog: ${product.status}');
    bool isProductActive = (product.status == "Active");
    _statusSwitch = isProductActive;

    print(
        '🔄 Setting status switch to: $_statusSwitch (Active: $isProductActive)');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 36, 50, 69),
            title: Text(
              'Edit Product',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  // Product Details
                  Text(
                    'Product: ${product.name}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    'ID: ${product.productId}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Supplier Price Section
                  Text(
                    'Supplier Price',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (product.priceSupplier != null)
                    Text(
                      'Current Supplier Price: \$${product.priceSupplier!.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                      ),
                    ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _priceController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 29, 41, 57),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Enter new price',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: Colors.white38,
                      ),
                      prefixText: '\$ ',
                      prefixStyle: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Status Section
                  Text(
                    'Product Status',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Current Status: ${product.status}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Status Switch with custom appearance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Set Product Active:',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                        ),
                      ),
                      Switch(
                        value: _statusSwitch,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.3),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withOpacity(0.3),
                        onChanged: (value) {
                          setState(() {
                            _statusSwitch = value;
                          });
                        },
                      ),
                    ],
                  ),

                  // Status explanation
                  Text(
                    _statusSwitch
                        ? 'Product will be visible to customers'
                        : 'Product will be hidden from customers',
                    style: GoogleFonts.spaceGrotesk(
                      color: _statusSwitch ? Colors.green : Colors.red,
                      fontSize: 13.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Get new values from dialog
                  final priceText = _priceController.text.trim();
                  final newPrice = double.tryParse(priceText);
                  final newStatus = _statusSwitch ? "Active" : "NotActive";

                  // Status has changed?
                  final statusChanged = (newStatus != product.status);

                  print(
                      '🔄 Status changed: $statusChanged (Original: ${product.status}, New: $newStatus)');

                  // Price has changed?
                  final priceChanged = newPrice != null &&
                      (product.priceSupplier == null ||
                          newPrice != product.priceSupplier);

                  // Close dialog
                  Navigator.of(context).pop();

                  // Process updates
                  if (priceChanged && statusChanged) {
                    _updateBoth(product.productId, newPrice!, newStatus);
                  } else if (priceChanged) {
                    _updatePrice(product.productId, newPrice!);
                  } else if (statusChanged) {
                    _updateStatus(product.productId, newStatus);
                  } else {
                    // No changes
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No changes were made')),
                    );
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  // Update both price and status in sequence
  Future<void> _updateBoth(int productId, double price, String status) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // First update price
      await _updatePriceApi(productId, price);

      // Then update status
      await _updateStatusApi(productId, status);

      // Refresh the products list
      await _fetchProducts();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update just the price
  Future<void> _updatePrice(int productId, double price) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _updatePriceApi(productId, price);
      await _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating price: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update just the status
// 1. First, modify the Update Status function to directly update the model:
  Future<void> _updateStatus(int productId, String status) async {
    // Find the product in our local list
    ProductModel? productToUpdate;
    for (var product in _allProducts) {
      if (product.productId == productId) {
        productToUpdate = product;
        break;
      }
    }

    if (productToUpdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Product not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save old status for comparison
    final oldStatus = productToUpdate.status;

    // Update the status locally BEFORE API call
    setState(() {
      productToUpdate?.status = status;
      _isLoading = true;
    });

    try {
      // API call to update status - whether it works or not, we keep our local update
      await _updateStatusApi(productId, status);

      // Set loading to false but preserve our local update
      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated from $oldStatus to $status'),
          backgroundColor: status == "Active" ? Colors.green : Colors.red,
        ),
      );

      // Optional: You can still trigger a background refresh
      // But don't wait for it or let it affect the UI
    } catch (e) {
      // On API error, we STILL keep our local change
      // (this is the key difference from before)
      setState(() {
        _isLoading = false;
        // DON'T revert the status change - keep what user requested
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Status may not be saved on server: $e'),
          backgroundColor: Colors.orange, // warning color
        ),
      );
    }
  }

  // API call to update price
  Future<void> _updatePriceApi(int productId, double price) async {
    if (_supplierId == null) {
      throw Exception('Supplier ID not found');
    }

    final headers = await AuthService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';

    print('🔄 Updating price for product $productId to $price');

    final url = Uri.parse(
        'https://finalproject-a5ls.onrender.com/supplierOrders/$_supplierId/products/$productId/price');

    final response = await http.patch(
      url,
      headers: headers,
      body: json.encode({'priceSupplier': price}),
    );

    print('📥 Price update response: ${response.statusCode}');

    if (response.statusCode != 200) {
      final message =
          json.decode(response.body)['message'] ?? 'Failed to update price';
      throw Exception(message);
    }
  }

  // API call to update status
  Future<void> _updateStatusApi(int productId, String status) async {
    if (_supplierId == null) {
      throw Exception('Supplier ID not found');
    }

    final headers = await AuthService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';

    print('🔄 Updating status for product $productId to $status');

    final url = Uri.parse(
        'https://finalproject-a5ls.onrender.com/supplierOrders/$_supplierId/products/$productId/price');

    final response = await http.patch(
      url,
      headers: headers,
      body: json.encode({'status': status}),
    );

    print('📥 Status update response: ${response.statusCode}');

    if (response.statusCode != 200) {
      final message =
          json.decode(response.body)['message'] ?? 'Failed to update status';
      throw Exception(message);
    }
  }

  /// Returns filtered, searched, and sorted products.
  List<ProductModel> get filteredProducts {
    List<ProductModel> temp = List.from(_allProducts);

    // Filter by status
    if (widget.selectedFilterIndex == 1) {
      // Active
      temp = temp.where((p) => p.status == "Active").toList();
    } else if (widget.selectedFilterIndex == 2) {
      // Not Active - handle both formats
      temp = temp
          .where((p) => p.status == "Not Active" || p.status == "NotActive")
          .toList();
    }

    // Search by name or product ID
    if (widget.searchQuery.isNotEmpty) {
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
              p.productId.toString().contains(widget.searchQuery))
          .toList();
    }

    // Apply sorting if set
    if (_sortColumnIndex != null) {
      if (_sortColumnIndex == 1) {
        // Modified to sort by supplier price instead of cost price
        temp.sort((a, b) {
          // Handle null supplier prices (sort them to the end)
          if (a.priceSupplier == null && b.priceSupplier == null) return 0;
          if (a.priceSupplier == null) return 1;
          if (b.priceSupplier == null) return -1;
          return a.priceSupplier!.compareTo(b.priceSupplier!);
        });
      }
      if (!_sortAscending) {
        temp = temp.reversed.toList();
      }
    }

    return temp;
  }

  /// Helper: builds a header label with a sort arrow.
  Widget _buildSortableColumnLabel(String label, int colIndex) {
    bool isSorted = _sortColumnIndex == colIndex;
    Widget arrow = SizedBox.shrink();
    if (isSorted) {
      arrow = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 14.sp,
        color: Colors.white,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(width: 4.w),
        arrow,
      ],
    );
  }

  /// Called when a sortable header is tapped.
  void _onSort(int colIndex) {
    setState(() {
      if (_sortColumnIndex == colIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = colIndex;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 105, 65, 198),
        ),
      );
    }

    final totalItems = filteredProducts.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;
    final visibleProducts = filteredProducts.isEmpty
        ? []
        : filteredProducts.sublist(startIndex, endIndex);

    // Heading row color
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    // Divider and border color/thickness
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
          ),
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wrap DataTable in horizontal SingleChildScrollView.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => Colors.transparent,
                    ),
                    showCheckboxColumn: false,
                    headingRowColor:
                        MaterialStateProperty.all<Color>(headingColor),
                    border: TableBorder(
                      top: dividerSide,
                      bottom: dividerSide,
                      left: dividerSide,
                      right: dividerSide,
                      horizontalInside: dividerSide2,
                      verticalInside: dividerSide2,
                    ),
                    columnSpacing: 20.w,
                    dividerThickness: 0,
                    headingTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.sp,
                    ),
                    columns: [
                      // ID Column
                      const DataColumn(label: Text("ID")),
                      // Image & Name Column
                      const DataColumn(label: Text("Image & Name")),
                      // Supplier Price Column (sortable) - replacing Cost Price
                      DataColumn(
                        label: _buildSortableColumnLabel("Supplier Price", 1),
                        onSort: (columnIndex, _) {
                          _onSort(1);
                        },
                      ),
                      // Category Column
                      const DataColumn(label: Text("Category")),
                      // Status Column
                      const DataColumn(label: Text("Status")),
                      // Actions Column (single Edit icon)
                      const DataColumn(label: Text("Actions")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        cells: [
                          // ID cell
                          DataCell(Text("${product.productId}")),
                          // Image & Name cell
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    product.image,
                                    width: 50.w,
                                    height: 50.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50.w,
                                        height: 50.h,
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white70,
                                          size: 24.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    product.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Supplier Price cell
                          DataCell(
                            product.priceSupplier != null
                                ? Text(
                                    "\$${product.priceSupplier!.toStringAsFixed(2)}")
                                : Text("Not set",
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                          ),
                          // Category cell
                          DataCell(Text(product.categoryName)),
                          // Status cell
                          DataCell(_buildStatusPill(product.status)),
                          // Actions cell with single Edit button
                          DataCell(
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: const Color.fromARGB(255, 105, 65, 198),
                                size: 22.sp,
                              ),
                              onPressed: () {
                                _showEditDialog(product);
                              },
                              tooltip: "Edit Product",
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination row
              if (filteredProducts.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                  child: Row(
                    children: [
                      Spacer(),
                      Text(
                        "Total $totalItems items",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Left arrow
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            size: 20.sp, color: Colors.white70),
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      Row(
                        children: List.generate(totalPages, (index) {
                          return _buildPageButton(index + 1);
                        }),
                      ),
                      // Right arrow
                      IconButton(
                        icon: Icon(Icons.arrow_forward,
                            size: 20.sp, color: Colors.white70),
                        onPressed: _currentPage < totalPages
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Status pill with different colors based on status.
  Widget _buildStatusPill(String status) {
    late Color bgColor;
    String displayStatus;

    // Handle both status formats and normalize display
    if (status == "Active") {
      bgColor = const Color.fromARGB(178, 0, 224, 116); // green
      displayStatus = "Active";
    } else if (status == "Not Active" || status == "NotActive") {
      bgColor = const Color.fromARGB(255, 229, 62, 62); // red
      displayStatus = "Not Active";
    } else {
      bgColor = Colors.grey; // default
      displayStatus = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
  }

  /// Pagination button builder.
  Widget _buildPageButton(int pageIndex) {
    final bool isSelected = (pageIndex == _currentPage);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          side: BorderSide(
            color: const Color.fromARGB(255, 34, 53, 62),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        ),
        onPressed: () {
          setState(() {
            _currentPage = pageIndex;
          });
        },
        child: Text(
          "$pageIndex",
          style: GoogleFonts.spaceGrotesk(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
