import 'dart:convert';
import 'dart:html' as html; // only for Flutter Web image picking
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/productsWidgets/product_item_Model.dart';
import 'package:storify/admin/widgets/productsWidgets/supplist.dart';

class ProductInformationCard extends StatefulWidget {
  final ProductItemInformation product;
  final ValueChanged<ProductItemInformation> onUpdate;

  const ProductInformationCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  @override
  State<ProductInformationCard> createState() => _ProductInformationCardState();
}

class _ProductInformationCardState extends State<ProductInformationCard> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;
  String _selectedCategoryName = 'Uncategorized';
  bool _imageChanged = false;

  // Local copy of product values for editing
  late String _imageUrl;
  late String _productName;
  late double _costPrice;
  late double _sellPrice;
  late int _quantity;
  late bool _isActive;

  late String? _description;
  late String? _barcode;
  late DateTime? _prodDate;
  late DateTime? _expDate;

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _warrantyController;
  late TextEditingController _descriptionController;
  late TextEditingController _prodDateController;
  late TextEditingController _expDateController;

  // GlobalKey for the drop area container
  final GlobalKey _dropAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize from product
    _imageUrl = widget.product.image;
    _productName = widget.product.name;
    _costPrice = widget.product.costPrice;
    _sellPrice = widget.product.sellPrice;
    _quantity = widget.product.qty;

    // Extract category name from category object
    if (widget.product.category != null) {
      if (widget.product.category is Map) {
        final categoryName = widget.product.category['categoryName'];
        if (categoryName != null && categoryName is String) {
          _selectedCategoryName = categoryName;
        }
      }
    }

    _isActive = widget.product.status == 'Active';

    _barcode = widget.product.barcode;
    _description = widget.product.description;

    // Parse dates if they exist
    _prodDate = widget.product.prodDate != null
        ? _parseDate(widget.product.prodDate!)
        : null;
    _expDate = widget.product.expDate != null
        ? _parseDate(widget.product.expDate!)
        : null;

    // Initialize controllers
    _nameController = TextEditingController(text: _productName);
    _costPriceController =
        TextEditingController(text: _costPrice.toStringAsFixed(2));
    _sellPriceController =
        TextEditingController(text: _sellPrice.toStringAsFixed(2));
    _quantityController = TextEditingController(text: _quantity.toString());

    _descriptionController = TextEditingController(text: _description ?? '');
    _prodDateController = TextEditingController(
        text: _prodDate != null
            ? DateFormat('yyyy-MM-dd').format(_prodDate!)
            : '');
    _expDateController = TextEditingController(
        text:
            _expDate != null ? DateFormat('yyyy-MM-dd').format(_expDate!) : '');

    // Add HTML drop listeners after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextObj = _dropAreaKey.currentContext;
      if (contextObj != null) {
        try {
          final htmlElement = (contextObj.findRenderObject() as dynamic)
              .debugCreator
              .element as html.Element;
          // Prevent default dragover events
          htmlElement.addEventListener('dragover', (html.Event event) {
            event.preventDefault();
          });
          // Handle file drops
          htmlElement.addEventListener('drop', (html.Event event) async {
            event.preventDefault();
            final dropEvent = event as html.MouseEvent;
            final dataTransfer = dropEvent.dataTransfer;
            if (dataTransfer != null && dataTransfer.files!.isNotEmpty) {
              final file = dataTransfer.files!.first;
              final reader = html.FileReader();
              reader.readAsDataUrl(file);
              reader.onLoadEnd.listen((event) {
                setState(() {
                  _imageUrl = reader.result as String;
                  _imageChanged = true;
                });
                print("Image updated via drop");
              });
            }
          });
        } catch (e) {
          print("Error attaching drop listener: $e");
        }
      }
    });
  }

  DateTime _parseDate(String dateString) {
    try {
      // Try different date formats
      if (dateString.contains('T')) {
        return DateTime.parse(dateString);
      } else {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          // Assuming MM/DD/YYYY format
          return DateTime(
              int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
        }
      }
    } catch (e) {
      print("Error parsing date: $e");
    }
    return DateTime.now(); // Default fallback
  }

  Future<void> _selectDate(BuildContext context, bool isProdDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isProdDate
          ? (_prodDate ?? DateTime.now())
          : (_expDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 105, 65, 198),
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 36, 50, 69),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 29, 41, 57),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isProdDate) {
          _prodDate = picked;
          _prodDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _expDate = picked;
          _expDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _warrantyController.dispose();
    _descriptionController.dispose();
    _prodDateController.dispose();
    _expDateController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() {
        _isEditing = true;
        _imageChanged = false; // Reset image changed flag
      });
    }
  }

  // Save changes to API with authentication
  Future<void> _saveChanges() async {
    // Extract values from controllers
    _productName = _nameController.text;
    _costPrice = double.tryParse(_costPriceController.text) ?? _costPrice;
    _sellPrice = double.tryParse(_sellPriceController.text) ?? _sellPrice;
    _quantity = int.tryParse(_quantityController.text) ?? _quantity;
  
    _description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if we're logged in first
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _error = "Not logged in. Only admin users can edit products.";
        });
        _showErrorDialog();
        return;
      }

      // Prepare data for API
      final Map<String, dynamic> updateData = {
        'name': _productName,
        'costPrice': _costPrice,
        'sellPrice': _sellPrice,
        'quantity': _quantity,
        'categoryId': widget.product.categoryId, // Keep original category ID
        'status': _isActive
            ? 'Active'
            : 'NotActive', // Use correct case for status values
      };

      // Include image if it was changed
      if (_imageChanged) {
        updateData['image'] = _imageUrl;
      }

      // Add optional fields only if they have values

      if (_description != null && _description!.isNotEmpty)
        updateData['description'] = _description;
      if (_prodDate != null)
        updateData['prodDate'] = DateFormat('yyyy-MM-dd').format(_prodDate!);
      if (_expDate != null)
        updateData['expDate'] = DateFormat('yyyy-MM-dd').format(_expDate!);
      if (_barcode != null && _barcode!.isNotEmpty)
        updateData['barcode'] = _barcode;

      // Debug the request body
      print('Sending update with body: ${json.encode(updateData)}');

      // Make API request with authentication headers
      final headers = await AuthService.getAuthHeaders();
      print('Making authenticated API request with headers: $headers');

      // First attempt - with all data including image if changed
      http.Response response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/product/${widget.product.productId}'),
        headers: headers,
        body: json.encode(updateData),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      // If first attempt fails and we included the image, try again without image
      if (response.statusCode != 200 &&
          _imageChanged &&
          (response.body.contains('image') || response.statusCode == 400)) {
        print('First attempt failed. Trying without image field.');
        // Remove image from update data
        updateData.remove('image');

        // Try API request again without image
        response = await http.put(
          Uri.parse(
              'https://finalproject-a5ls.onrender.com/product/${widget.product.productId}'),
          headers: headers,
          body: json.encode(updateData),
        );

        print('Second attempt status: ${response.statusCode}');
        print('Second attempt body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Success - create an updated product object for the UI
        final updatedProduct = ProductItemInformation(
          productId: widget.product.productId,
          image: _imageUrl,
          name: _productName,
          costPrice: _costPrice,
          sellPrice: _sellPrice,
          qty: _quantity,
          categoryId: widget.product.categoryId,
          category: widget.product.category,
          status: _isActive ? 'Active' : 'NotActive', // Match API format
          barcode: _barcode,

          prodDate: _prodDate != null
              ? DateFormat('yyyy-MM-dd').format(_prodDate!)
              : null,
          expDate: _expDate != null
              ? DateFormat('yyyy-MM-dd').format(_expDate!)
              : null,
          description: _description,
          suppliers: widget.product.suppliers,
        );
        // Call the onUpdate callback
        widget.onUpdate(updatedProduct);

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_imageChanged && !updateData.containsKey('image')
                ? 'Product updated successfully (without image changes)'
                : 'Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        // Authentication error
        setState(() {
          _isLoading = false;
          _error = 'Authentication failed. Please log in as admin.';
        });
        _showErrorDialog();
      } else {
        // Other errors
        setState(() {
          _isLoading = false;
          _error =
              'Failed to update product: ${response.statusCode}\n${response.body}';
        });
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        title: Text(
          'Error',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          _error ?? 'Failed to update product.',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This function handles image selection
  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final html.File file = files.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _imageUrl = reader.result as String;
            _imageChanged = true;
          });
        });
      }
    });
  }

  // Updated ProductInformationCard build method without suppliers section
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 510,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 105, 65, 198),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row and Edit/Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Product Information",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                  onPressed: _toggleEditing,
                  child: Text(
                    _isEditing ? "Save" : "Edit",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Three-column layout: Image, Details1, Details2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    key: _dropAreaKey,
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1, // 1:1 aspect ratio for the image
                          child: InkWell(
                            onTap: _isEditing ? _pickImage : null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Drop or Import",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Column 2: First set of details
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        title: "Product ID",
                        child: Text(
                          "${widget.product.productId}",
                          style: _labelStyle(),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Product Name",
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                                decoration:
                                    _inputDecoration("Enter product name"),
                              )
                            : Text(
                                _productName,
                                style: _labelStyle(),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Cost Price",
                        child: _isEditing
                            ? TextField(
                                controller: _costPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                                decoration:
                                    _inputDecoration("Enter cost price"),
                              )
                            : Text(
                                "\$${_costPrice.toStringAsFixed(2)}",
                                style: _labelStyle(),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Sell Price",
                        child: _isEditing
                            ? TextField(
                                controller: _sellPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                                decoration:
                                    _inputDecoration("Enter sell price"),
                              )
                            : Text(
                                "\$${_sellPrice.toStringAsFixed(2)}",
                                style: _labelStyle(),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Quantity",
                        child: _isEditing
                            ? TextField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                                decoration: _inputDecoration("Enter quantity"),
                              )
                            : Text(
                                "$_quantity",
                                style: _labelStyle(),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Category",
                        child: Text(
                          _selectedCategoryName,
                          style: _labelStyle(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),

                // Column 3: Second set of details
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        title: "Barcode",
                        child: Text(
                          _barcode ?? "Not available",
                          style: _labelStyle(),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Status",
                        child: _isEditing
                            ? DropdownButtonFormField<String>(
                                value: _isActive ? 'Active' : 'NotActive',
                                dropdownColor:
                                    const Color.fromARGB(255, 36, 50, 69),
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                                decoration: _inputDecorationDropdown(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Active', child: Text("Active")),
                                  DropdownMenuItem(
                                      value: 'NotActive',
                                      child: Text("Not Active")),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _isActive = value == 'Active';
                                    });
                                  }
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isActive
                                      ? const Color.fromARGB(178, 0, 224, 116)
                                      : const Color.fromARGB(255, 229, 62, 62),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _isActive ? "Active" : "Not Active",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
          
                   
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Production Date",
                        child: _isEditing
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _prodDateController,
                                      style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white),
                                      decoration:
                                          _inputDecoration("YYYY-MM-DD"),
                                      readOnly: true,
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 20,
                                    icon: const Icon(Icons.calendar_today,
                                        color: Colors.white),
                                    onPressed: () => _selectDate(context, true),
                                  ),
                                ],
                              )
                            : Text(
                                _prodDate != null
                                    ? DateFormat('yyyy-MM-dd')
                                        .format(_prodDate!)
                                    : "Not specified",
                                style: _labelStyle(),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        title: "Expiry Date",
                        child: _isEditing
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _expDateController,
                                      style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white),
                                      decoration:
                                          _inputDecoration("YYYY-MM-DD"),
                                      readOnly: true,
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 20,
                                    icon: const Icon(Icons.calendar_today,
                                        color: Colors.white),
                                    onPressed: () =>
                                        _selectDate(context, false),
                                  ),
                                ],
                              )
                            : Text(
                                _expDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_expDate!)
                                    : "Not specified",
                                style: _labelStyle(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description - Full width below the three columns
            SizedBox(height: 20.h),
            _buildDetailRow(
              title: "Description",
              child: _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      maxLines: 3,
                      decoration: _inputDecoration("Enter product description"),
                    )
                  : Text(
                      _description ?? "No description available",
                      style: _labelStyle(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for building each detail row
  Widget _buildDetailRow({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 54, 68, 88),
      hintText: hint,
      hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  InputDecoration _inputDecorationDropdown() {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 54, 68, 88),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.spaceGrotesk(
      fontSize: 16.sp,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
  }
}
