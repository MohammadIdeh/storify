// category_products_row.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/categoryWidgets/ProductDetailCard.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart';
import 'package:http_parser/http_parser.dart';

class CategoryProductsRow extends StatefulWidget {
  final String categoryName;
  final int categoryID;
  final String? description;
  final String? currentImage; // Add this to get current image
  final List<ProductDetail> products;
  final VoidCallback? onClose;
  final ValueChanged<ProductDetail> onProductDelete;
  final ValueChanged<CategoryItem>? onCategoryUpdate;

  const CategoryProductsRow({
    super.key,
    required this.categoryName,
    required this.categoryID,
    this.description,
    this.currentImage, // Add this parameter
    required this.products,
    this.onClose,
    required this.onProductDelete,
    this.onCategoryUpdate,
  });

  @override
  State<CategoryProductsRow> createState() => _CategoryProductsRowState();
}

class _CategoryProductsRowState extends State<CategoryProductsRow> {
  String _searchQuery = "";

  // Edit mode state
  bool _isEditing = false;
  bool _isUpdating = false;
  String? _errorMessage;

  // Local copies for editing
  late String _editingName;
  late String _editingDescription;
  late bool _editingIsActive;
  late String _editingImage;
  String? _base64Image; // For new uploaded image

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _initializeEditingValues();
  }

  void _initializeEditingValues() {
    _editingName = widget.categoryName;
    _editingDescription = widget.description ?? '';
    _editingIsActive = true;
    _editingImage = widget.currentImage ?? ''; // Use current image

    _nameController = TextEditingController(text: _editingName);
    _descriptionController = TextEditingController(text: _editingDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<ProductDetail> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.products;
    }

    final startsWith = <ProductDetail>[];
    final contains = <ProductDetail>[];

    for (final prod in widget.products) {
      final lowerName = prod.name.toLowerCase();
      if (lowerName.startsWith(query)) {
        startsWith.add(prod);
      } else if (lowerName.contains(query)) {
        contains.add(prod);
      }
    }

    return [...startsWith, ...contains];
  }

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

        // Check file size - 5MB limit
        final fileSize = file.size;
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage =
                "Image size exceeds 5MB limit. Please choose a smaller image.";
          });
          return;
        }

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          try {
            final dataUrl = reader.result as String;
            setState(() {
              _editingImage = dataUrl;
              // Extract base64 data
              final String base64Data =
                  dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
              _base64Image = base64Data;
              _errorMessage = null;
            });
          } catch (e) {
            setState(() {
              _errorMessage = "Error processing image: $e";
            });
          }
        });
      }
    });
  }

  void _toggleEditing() {
    setState(() {
      _errorMessage = null;

      if (_isEditing) {
        _saveChanges();
      } else {
        // When starting edit mode, load current image
        _editingImage = widget.currentImage ?? '';
        _base64Image = null; // Reset new image selection
        _isEditing = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    // Validate inputs
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = "Category name cannot be empty";
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final success = await _updateCategoryInAPI();
      if (success) {
        setState(() {
          _editingName = name;
          _editingDescription = _descriptionController.text.trim();
          _isEditing = false;
          _isUpdating = false;
        });

        // Notify parent of the update
        if (widget.onCategoryUpdate != null) {
          final updatedCategory = CategoryItem(
            categoryID: widget.categoryID,
            categoryName: _editingName,
            slug: '',
            description: _editingDescription,
            status: _editingIsActive ? 'Active' : 'NotActive',
            image: _editingImage,
          );
          widget.onCategoryUpdate!(updatedCategory);
        }
      } else {
        setState(() {
          _isUpdating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update: $e";
        _isUpdating = false;
      });
    }
  }

  Future<bool> _updateCategoryInAPI() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication required. Please log in again.";
        });
        return false;
      }

      // Create a multipart request for image upload
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/category/${widget.categoryID}'),
      );

      // Add token header
      request.headers['token'] = token;

      // Add form fields
      request.fields['categoryName'] = _nameController.text.trim();
      request.fields['status'] = _editingIsActive ? 'Active' : 'NotActive';
      request.fields['description'] = _descriptionController.text.trim();

      // Add image if a new one was selected
      if (_base64Image != null) {
        final imageBytes = base64Decode(_base64Image!);
        final imageFile = http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'category_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(imageFile);
      }

      print('Updating category ${widget.categoryID}...');

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );

      final response = await http.Response.fromStream(streamedResponse);

      print('API Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        try {
          final responseData = json.decode(response.body);
          setState(() {
            _errorMessage = responseData['message'] ??
                'Failed to update category: ${response.statusCode}';
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to update category: ${response.statusCode}';
          });
        }
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating category: $e';
      });
      return false;
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 12.sp),
      filled: true,
      fillColor: const Color.fromARGB(255, 54, 68, 88),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8.r),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: _isEditing ? 350 : 450, // Smaller when editing
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message if there is one
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.r),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.red,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isEditing) ...[
              // EDIT MODE - Clean, compact layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Image area (square)
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 120.w,
                      height: 120.w, // Square aspect ratio
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 54, 68, 88),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: _editingImage.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    color: Colors.white70, size: 24.sp),
                                SizedBox(height: 4.h),
                                Text(
                                  "Upload\nImage",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white70,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                _editingImage,
                                width: 120.w,
                                height: 120.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120.w,
                                    height: 120.w,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade600,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                      size: 24.sp,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Right side - Form fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name input (compact)
                        SizedBox(
                          width: 300.w, // Fixed smaller width
                          child: TextField(
                            controller: _nameController,
                            decoration: _buildInputDecoration("Category Name"),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Description input (compact)
                        SizedBox(
                          width: 400.w, // Fixed smaller width
                          child: TextField(
                            controller: _descriptionController,
                            decoration: _buildInputDecoration("Description"),
                            maxLines: 2,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Status toggle
                        Row(
                          children: [
                            Text(
                              "Status: ",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                            Switch(
                              value: _editingIsActive,
                              onChanged: (value) {
                                setState(() {
                                  _editingIsActive = value;
                                });
                              },
                              activeColor:
                                  const Color.fromARGB(255, 105, 65, 198),
                            ),
                            Text(
                              _editingIsActive ? "Active" : "NotActive",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Action buttons for edit mode
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Cancel button
                  TextButton(
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.3), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: _isUpdating
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _errorMessage = null;
                              // Reset to original values
                              _nameController.text = widget.categoryName;
                              _descriptionController.text =
                                  widget.description ?? '';
                              _editingImage = widget.currentImage ?? '';
                              _base64Image = null;
                            });
                          },
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: _isUpdating
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Save button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 139, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      elevation: 1,
                    ),
                    onPressed: _isUpdating ? null : _saveChanges,
                    child: _isUpdating
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save,
                                  color: Colors.white, size: 16.sp),
                              SizedBox(width: 4.w),
                              Text(
                                "Save",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ] else ...[
              // VIEW MODE - Original layout with products
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.description != null &&
                            widget.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              widget.description!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search field
                  SizedBox(
                    width: 200.w,
                    height: 40.h,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle:
                            GoogleFonts.spaceGrotesk(color: Colors.white70),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 68, 88),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Edit button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(100.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: _toggleEditing,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 18.sp),
                        SizedBox(width: 4.w),
                        Text(
                          "Edit",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Close button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(100.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: widget.onClose,
                    child: Text(
                      "Close",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Products section (only show when NOT editing)
              if (widget.products.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products in this category",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Products added to this category will appear here",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _filteredProducts
                          .map((prod) => SizedBox(
                                width: 250,
                                key: ValueKey(prod.productID ?? prod.name),
                                child: ProductDetailCard(
                                  product: prod,
                                  categoryID: widget.categoryID,
                                  onUpdate: (updatedProduct) {
                                    print(
                                        "Updated product: ${updatedProduct.name}");
                                  },
                                  onDelete: () {
                                    widget.onProductDelete(prod);
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
