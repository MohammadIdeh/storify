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
  final String status;
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
    return ProductModel(
      productId: json['productId'],
      name: json['name'],
      image: json['image'] ?? 'https://picsum.photos/200',
      costPrice: double.parse(json['costPrice'].toString()),
      sellPrice: double.parse(json['sellPrice'].toString()),
      categoryName: json['category']['categoryName'] ?? 'Unknown',
      status: json['status'] ?? 'Not Active',
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
  final int _itemsPerPage = 9;
  TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSupplierId().then((_) => _fetchProducts());
  }

  void refreshProducts() {
    print('Refreshing products table, clearing existing data...');

    // Clear existing products first
    setState(() {
      _allProducts = [];
      _isLoading = true;
    });

    // Force a clean fetch with a longer delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchProducts().then((_) {
        print(
            'Products refresh completed. Found ${_allProducts.length} products');
        // If no products found, try one more time after a delay
        if (_allProducts.isEmpty) {
          print('No products found, trying once more...');
          Future.delayed(const Duration(milliseconds: 1000), () {
            _fetchProducts().then((_) {
              print(
                  'Second refresh completed. Found ${_allProducts.length} products');
            });
          });
        }
      });
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
    print(
        '📦 Loaded supplierId for table: $_supplierId - Products will be fetched for this ID');

    // Print the token to check if it contains the correct supplier ID
    final token = await AuthService.getToken();
    print(
        '🔑 Using auth token: ${token?.substring(0, 20)}... (${token?.length} chars)');
  }

  // Fetch products from the API
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
      print('📤 Fetching products for supplier ID: $_supplierId');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/supplierOrders/supplier/$_supplierId/products'),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Data received: ${data['products']?.length ?? 0} products');

        if (data['products'] != null && data['products'] is List) {
          List<ProductModel> products = [];

          for (var product in data['products']) {
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

  // Update product price
  Future<void> _updateProductPrice(int productId, double price) async {
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplier ID not found')),
      );
      return;
    }

    try {
      // Get auth headers and add Content-Type
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Log request details for debugging
      print(
          '🔄 Updating price for product $productId with supplier $_supplierId');
      print('📤 Request body: ${json.encode({'priceSupplier': price})}');
      print('🔑 Request headers: $headers');

      final url = Uri.parse(
          'https://finalproject-a5ls.onrender.com/supplierOrders/$_supplierId/products/$productId/price');
      print('🌐 Request URL: $url');

      // Make the API call
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({'priceSupplier': price}),
      );

      // Log full response for debugging
      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Price updated: ${data['message']}');

        // Refresh products list
        await _fetchProducts();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Price updated successfully')),
        );
      } else {
        print(
            '⚠️ Error updating price: ${response.statusCode}, ${response.body}');

        // Show more detailed error message
        String errorMessage = 'Failed to update price';

        try {
          // Try to extract error message from response body
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If parsing fails, use the default message
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('⚠️ Exception updating price: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Show update price dialog
  Future<void> _showUpdatePriceDialog(ProductModel product) async {
    // Initialize with current price (or cost price if no supplier price set)
    _priceController.text =
        product.priceSupplier?.toString() ?? product.costPrice.toString();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          title: Text(
            'Update Price',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Product: ${product.name} (ID: ${product.productId})',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Current Cost Price: \$${product.costPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                  ),
                ),
                if (product.priceSupplier != null)
                  Text(
                    'Current Supplier Price: \$${product.priceSupplier!.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                    ),
                  ),
                SizedBox(height: 16.h),
                Text(
                  'New Supplier Price',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    prefixText: '\$ ',
                    prefixStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                    ),
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
            TextButton(
              child: Text(
                'Update',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color.fromARGB(255, 105, 65, 198),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                final priceText = _priceController.text.trim();
                final newPrice = double.tryParse(priceText);
                if (newPrice != null) {
                  print(
                      '💲 Updating product ${product.productId} price to: $newPrice');
                  _updateProductPrice(product.productId, newPrice);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Returns filtered, searched, and sorted products.
  List<ProductModel> get filteredProducts {
    List<ProductModel> temp = List.from(_allProducts);

    // Filter by status
    if (widget.selectedFilterIndex == 1) {
      // Active
      temp = temp.where((p) => p.status == "Active").toList();
    } else if (widget.selectedFilterIndex == 2) {
      // Not Active
      temp = temp.where((p) => p.status == "Not Active").toList();
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
        temp.sort((a, b) => a.costPrice.compareTo(b.costPrice));
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
          clipBehavior:
              Clip.antiAlias, // Ensures rounded corners clip child content
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
                      // Cost Price Column (sortable)
                      DataColumn(
                        label: _buildSortableColumnLabel("Cost Price", 1),
                        onSort: (columnIndex, _) {
                          _onSort(1);
                        },
                      ),
                      // Category Column
                      const DataColumn(label: Text("Category")),
                      // Status Column
                      const DataColumn(label: Text("Status")),
                      // Supplier Price Column
                      const DataColumn(label: Text("Supplier Price")),
                      // Actions Column (Update Price icon)
                      const DataColumn(label: Text("Actions")),
                    ],
                    rows: visibleProducts.map((product) {
                      return DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            // For now just show a snackbar to indicate row was clicked
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Product ${product.name} selected'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
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
                          // Cost Price cell
                          DataCell(Text(
                              "\$${product.costPrice.toStringAsFixed(2)}")),
                          // Category cell
                          DataCell(Text(product.categoryName)),
                          // Status cell
                          DataCell(
                            _buildStatusPill(product.status),
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
                          // Actions cell
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.push_pin,
                                    color: Colors.amber,
                                    size: 20.sp,
                                  ),
                                  onPressed: () {
                                    _showUpdatePriceDialog(product);
                                  },
                                  tooltip: "Update Supplier Price",
                                ),
                              ],
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

    switch (status) {
      case "Active":
        bgColor = const Color.fromARGB(178, 0, 224, 116); // green
        break;
      case "Not Active":
        bgColor = const Color.fromARGB(255, 229, 62, 62); // red
        break;
      default:
        bgColor = Colors.grey; // default
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        status,
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
