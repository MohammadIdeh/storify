import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';

class Addnewproductwidget extends StatefulWidget {
  final Function() onCancel;
  final Function(Map<String, dynamic>) onAddProduct;
  final int supplierId;

  const Addnewproductwidget({
    super.key,
    required this.onCancel,
    required this.onAddProduct,
    required this.supplierId,
  });

  @override
  State<Addnewproductwidget> createState() => _AddnewproductwidgetState();
}

class _AddnewproductwidgetState extends State<Addnewproductwidget> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown selections
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];

  // Image handling for web
  bool _isUploading = false;
  bool _isLoading = true;
  html.File? _imageFile;
  String? _imagePreviewUrl;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch categories from API
      final response = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/category/getall'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] != null && data['categories'] is List) {
          final List<Map<String, dynamic>> categories = [];

          for (var category in data['categories']) {
            categories.add({
              'id': category['categoryID'],
              'name': category['categoryName'],
            });
          }

          setState(() {
            _categories = categories;
            _selectedCategory =
                categories.isNotEmpty ? categories[0]['name'] : null;
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid categories data structure');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading categories: $e';
        _isLoading = false;
      });
      print('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    if (_imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }
    super.dispose();
  }

  void _pickImageForWeb() {
    // Create a file input element
    final html.FileUploadInputElement input = html.FileUploadInputElement()
      ..accept = 'image/*';

    // Add a listener for when a file is selected
    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();

        reader.onLoad.listen((e) {
          setState(() {
            _imageFile = file;
            // Create a URL for the image preview
            if (_imagePreviewUrl != null) {
              html.Url.revokeObjectUrl(_imagePreviewUrl!);
            }
            _imagePreviewUrl = html.Url.createObjectUrl(file);
          });
        });

        reader.readAsDataUrl(file);
      }
    });

    // Trigger click on the input element
    input.click();
  }

// In the _submitForm method, remove the supplierId from the form data:

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an image for the product'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        // Get auth token
        final token = await AuthService.getToken();

        // For web, we need to create a FormData and add the file
        final formData = html.FormData();

        // Add text fields
        formData.append('name', _nameController.text);
        formData.append('costPrice', _costPriceController.text);
        formData.append('sellPrice', _sellPriceController.text);
        formData.append('categoryName', _selectedCategory!);
        formData.append('barcode', _barcodeController.text);
        if (_descriptionController.text.isNotEmpty) {
          formData.append('description', _descriptionController.text);
        }

        // REMOVED: formData.append('supplierId', widget.supplierId.toString());
        // The API extracts supplierId from the auth token

        // Add the image file
        formData.appendBlob('image', _imageFile!, _imageFile!.name);

        // Send the request using XMLHttpRequest
        final request = html.HttpRequest();
        request.open(
            'POST', 'https://finalproject-a5ls.onrender.com/request-product/');

        // Add authorization header
        if (token != null) {
          request.setRequestHeader('Authorization', 'Bearer $token');
        }

        request.onLoad.listen((event) {
          setState(() {
            _isUploading = false;
          });

          if (request.status == 201) {
            print(
                '✅ Product added successfully! Response: ${request.responseText}');

            // Add a short delay before calling onAddProduct to ensure server processing is complete
            Future.delayed(const Duration(milliseconds: 1000), () {
              widget.onAddProduct({
                'name': _nameController.text,
                'costPrice': _costPriceController.text,
                'sellPrice': _sellPriceController.text,
                'categoryName': _selectedCategory!,
                'barcode': _barcodeController.text,
                'image': _imagePreviewUrl!,
                'status': 'Active'
              });
            });
          } else {
            String errorMessage = 'Failed to submit product request';

            // Check if responseText is not null before trying to parse it
            if (request.responseText != null &&
                request.responseText!.isNotEmpty) {
              try {
                final responseData = json.decode(request.responseText!);
                if (responseData['message'] != null) {
                  errorMessage = responseData['message'].toString();
                }
              } catch (e) {
                // Parsing error, use default message
                print('Error parsing response: $e');
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

        // Add debugging for response errors
        request.onError.listen((event) {
          print('Request error: ${request.statusText}');
          setState(() {
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting product request'),
              backgroundColor: Colors.red,
            ),
          );
        });

        request.send(formData);
      } catch (e) {
        print('Error submitting product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking role and fetching categories
    if (_isLoading) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 105, 65, 198),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if categories couldn't be loaded
    if (_errorMessage.isNotEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 20.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Categories',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onCancel,
              child: Text(
                'Close',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Main form UI
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Product',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Form fields in a grid layout
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 7,
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
                _buildDropdown(
                  label: 'Category',
                  value: _selectedCategory!,
                  items: _categories.map((c) => c['name'] as String).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
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

                // Barcode
                _buildTextField(
                  controller: _barcodeController,
                  label: 'Barcode',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter barcode';
                    }
                    return null;
                  },
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Description field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description (Optional)',
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
                    fillColor: const Color.fromARGB(255, 29, 41, 57),
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

            SizedBox(height: 24.h),

            // Image Upload Section
            Row(
              children: [
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 29, 41, 57),
                    borderRadius: BorderRadius.circular(12),
                    image: _imagePreviewUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_imagePreviewUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imagePreviewUrl == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 36.sp,
                                color: Colors.white60,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Select Image",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white60,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _pickImageForWeb,
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

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 16.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 16.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isUploading ? null : _submitForm,
                  child: _isUploading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          'Add Product',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to build form elements
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
            fillColor: const Color.fromARGB(255, 29, 41, 57),
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
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
            color: const Color.fromARGB(255, 29, 41, 57),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color.fromARGB(255, 36, 50, 69),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
