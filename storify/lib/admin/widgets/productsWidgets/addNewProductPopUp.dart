import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:http_parser/http_parser.dart';

class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? status;
  final String? image;

  Category({required this.id, required this.name, this.status, this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['categoryID'],
      name: json['categoryName'],
      status: json['status'],
      image: json['image'],
    );
  }
}

class AddProductPopUp extends StatefulWidget {
  const AddProductPopUp({Key? key}) : super(key: key);

  @override
  State<AddProductPopUp> createState() => _AddProductPopUpState();
}

class _AddProductPopUpState extends State<AddProductPopUp> {
  final _formKey = GlobalKey<FormState>();

  // Product form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _prodDate;
  DateTime? _expDate;

  // For web file handling
  html.File? _imageFile;
  String? _imagePreviewUrl;
  String? _imageUrl;

  // Dropdown selections
  String _status = 'Active';
  int? _selectedCategoryId;
  int? _selectedSupplierId;

  // Data for dropdowns
  List<Supplier> _suppliers = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _fetchCategories();

    // Add a short delay to ensure state is properly initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // Just trigger a rebuild
        });
      }
    });
  }

  Future<void> _fetchSuppliers() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/supplier/suppliers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['suppliers'] != null) {
          setState(() {
            _suppliers = (data['suppliers'] as List)
                .map((supplier) => Supplier.fromJson(supplier))
                .toList();
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = 'You are not authorized to access this feature.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load suppliers. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch categories
  Future<void> _fetchCategories() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/category/getall'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] != null) {
          setState(() {
            _categories = (data['categories'] as List)
                .map((category) => Category.fromJson(category))
                .toList();
            print("Loaded ${_categories.length} categories"); // Debug print
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('Not authorized to fetch categories: ${response.statusCode}');
        // We don't set error message here as we'll show it from suppliers fetch
      } else {
        // If categories can't be loaded, we can still continue
        print('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    // Create a file input element
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';

    // Add a listener to handle file selection
    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        setState(() {
          _imageFile = file;

          // Create a preview URL for the image
          _imagePreviewUrl = html.Url.createObjectUrlFromBlob(file);
        });
      }
    });

    // Trigger click to open file picker
    input.click();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication token is required');
      }

      // Create a multipart request for the product
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://finalproject-a5ls.onrender.com/product/add'),
      );

      // Add token header - note that the API expects 'token', not 'Authorization'
      request.headers['token'] = token;

      // Add all product data as form fields
      request.fields['name'] = _nameController.text;
      request.fields['costPrice'] = _costPriceController.text;
      request.fields['sellPrice'] = _sellPriceController.text;
      request.fields['quantity'] = _quantityController.text;
      request.fields['categoryId'] = _selectedCategoryId.toString();
      request.fields['status'] = _status;
      request.fields['supplierIds[]'] = _selectedSupplierId.toString();
      // Add optional fields only if they have values
      if (_barcodeController.text.isNotEmpty) {
        request.fields['barcode'] = _barcodeController.text;
      }

      if (_prodDate != null) {
        request.fields['prodDate'] =
            DateFormat('yyyy-MM-dd').format(_prodDate!);
      }

      if (_expDate != null) {
        request.fields['expDate'] = DateFormat('yyyy-MM-dd').format(_expDate!);
      }

      if (_descriptionController.text.isNotEmpty) {
        request.fields['description'] = _descriptionController.text;
      }

      // Add image if selected
      if (_imageFile != null) {
        // For web, we need to use a different approach
        final reader = html.FileReader();
        final completer = Completer<List<int>>();

        // Set up the onLoad handler before starting the read operation
        reader.onLoad.listen((event) {
          final result = reader.result;
          if (result is String) {
            // The result is a Data URL: data:image/jpeg;base64,/9j/4AAQ...
            final bytes = base64.decode(result.split(',')[1]);
            completer.complete(bytes);
          } else {
            completer.completeError('Failed to read file as data URL');
          }
        });

        reader.onError.listen((event) {
          completer.completeError('Error reading file: ${reader.error}');
        });

        // Read the file as a data URL (base64)
        reader.readAsDataUrl(_imageFile!);

        // Wait for the read operation to complete
        final bytes = await completer.future;

        // Create a MultipartFile from the bytes
        final imageFile = http.MultipartFile.fromBytes(
          'image', // Field name must be 'image'
          bytes,
          filename: _imageFile!.name,
          contentType: MediaType.parse(_imageFile!.type),
        );

        // Add the file to the request
        request.files.add(imageFile);
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Product added successfully
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Unauthorized access
        throw Exception('You are not authorized to add products');
      } else {
        // Error adding product
        String errorMessage = 'Failed to add product: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to convert Blob to Uint8List
  Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    reader.onLoadEnd.listen((_) {
      completer.complete(Uint8List.fromList(
        (reader.result as dynamic).buffer.asUint8List(),
      ));
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 800.w,
        constraints: BoxConstraints(maxHeight: 700.h),
        padding: EdgeInsets.all(24.w),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white)))
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Text(
                                'Add New Product',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // Product Form
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                            childAspectRatio: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // Product Name
                              _buildTextField(
                                controller: _nameController,
                                label: 'Product Name',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter product name';
                                  }
                                  return null;
                                },
                              ),

                              // Category Dropdown
                              _buildDropdown<Category>(
                                label: 'Category',
                                items: _categories,
                                displayProperty: (category) => category.name,
                                valueProperty: (category) => category.id,
                                value: _selectedCategoryId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                              ),

                              // Cost Price
                              _buildTextField(
                                controller: _costPriceController,
                                label: 'Cost Price',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter cost price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),

                              // Sell Price
                              _buildTextField(
                                controller: _sellPriceController,
                                label: 'Sell Price',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter sell price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),

                              // Quantity
                              _buildTextField(
                                controller: _quantityController,
                                label: 'Quantity',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),

                              // Status Dropdown
                              _buildDropdown<String>(
                                label: 'Status',
                                items: ['Active', 'NotActive'],
                                displayProperty: (status) => status,
                                valueProperty: (status) => status,
                                value: _status,
                                onChanged: (value) {
                                  setState(() {
                                    _status = value!;
                                  });
                                },
                              ),

                              // Barcode (Optional)
                              _buildTextField(
                                controller: _barcodeController,
                                label: 'Barcode (Optional)',
                              ),

                              // Production Date (Optional)
                              _buildDatePicker(
                                label: 'Production Date (Optional)',
                                value: _prodDate,
                                onChanged: (date) {
                                  setState(() {
                                    _prodDate = date;
                                  });
                                },
                              ),

                              // Expiry Date (Optional)
                              _buildDatePicker(
                                label: 'Expiry Date (Optional)',
                                value: _expDate,
                                onChanged: (date) {
                                  setState(() {
                                    _expDate = date;
                                  });
                                },
                              ),

                              // Supplier Dropdown
                              _buildDropdown<Supplier>(
                                label: 'Supplier',
                                items: _suppliers,
                                displayProperty: (supplier) => supplier.name,
                                valueProperty: (supplier) => supplier.id,
                                value: _selectedSupplierId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSupplierId = value;
                                  });
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // Description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 36, 50, 69),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter product description',
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: Colors.white60,
                                  ),
                                ),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // Image Upload
                          Row(
                            children: [
                              Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 36, 50, 69),
                                  borderRadius: BorderRadius.circular(12),
                                  image: _imagePreviewUrl != null
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(_imagePreviewUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imagePreviewUrl == null
                                    ? Icon(
                                        Icons.image,
                                        color: Colors.white60,
                                        size: 40.sp,
                                      )
                                    : null,
                              ),
                              SizedBox(width: 16.w),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _pickImage,
                                child: Text(
                                  'Upload Image',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 32.h),

                          // Submit Button
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 105, 65, 198),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 48.w,
                                  vertical: 16.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _submitProduct,
                              child: Text(
                                'Add Product',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 36, 50, 69),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.white60,
            ),
          ),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
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
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 50, 69),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  value != null
                      ? DateFormat('yyyy-MM-dd').format(value)
                      : 'Select Date',
                  style: GoogleFonts.spaceGrotesk(
                    color: value != null ? Colors.white : Colors.white60,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white60,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required String Function(T) displayProperty,
    required dynamic Function(T) valueProperty,
    required dynamic value,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color.fromARGB(255, 36, 50, 69),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items.isEmpty
                  ? [
                      DropdownMenuItem<dynamic>(
                        value: null,
                        child: Text(
                          'No items available',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white60,
                          ),
                        ),
                      )
                    ]
                  : items.map((T item) {
                      return DropdownMenuItem<dynamic>(
                        value: valueProperty(item),
                        child: Text(
                          displayProperty(item),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
              hint: Text(
                'Select $label',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white60,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();

    _descriptionController.dispose();

    // Release object URLs when disposing
    if (_imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }

    super.dispose();
  }
}
