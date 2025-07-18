import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
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

  // Flag to prevent multiple calls
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Safe to call in initState as it doesn't use localization
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only run once and only after the localization context is available
    if (!_hasInitialized) {
      _hasInitialized = true;
      _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
          throw Exception(l10n.invalidCategoriesData);
        }
      } else {
        throw Exception(
            '${l10n.failedToLoadCategories}: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.errorLoadingCategories}: $e';
        _isLoading = false;
      });
      debugPrint('Error loading categories: $e');
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

  Future<void> _submitForm() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectImage),
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
            debugPrint(
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
            String errorMessage = l10n.failedToSubmitProductRequest;

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
                debugPrint('Error parsing response: $e');
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
          debugPrint('Request error: ${request.statusText}');
          setState(() {
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorSubmittingProductRequest),
              backgroundColor: Colors.red,
            ),
          );
        });

        request.send(formData);
      } catch (e) {
        debugPrint('Error submitting product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorPrefix}$e'),
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Show loading indicator while checking role and fetching categories
    if (_isLoading) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
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
                  l10n.loadingText,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16.sp,
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error message if categories couldn't be loaded
    if (_errorMessage.isNotEmpty) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
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
                l10n.errorLoadingCategoriesTitle,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
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
                  l10n.closeButton,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main form UI
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
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
                    l10n.addNewProduct,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
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
                    label: l10n.productName,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterProductName;
                      }
                      return null;
                    },
                  ),

                  // Category Dropdown
                  _buildDropdown(
                    label: l10n.categoryLabel,
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
                    label: l10n.costPrice,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterCostPrice;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),

                  // Sell Price
                  _buildTextField(
                    controller: _sellPriceController,
                    label: l10n.sellPrice,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterSellPrice;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.pleaseEnterValidNumber;
                      }
                      return null;
                    },
                  ),

                  // Barcode
                  _buildTextField(
                    controller: _barcodeController,
                    label: l10n.barcodeLabel,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterBarcode;
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
                    l10n.descriptionOptional,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    textDirection:
                        isRtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 29, 41, 57),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: l10n.enterProductDescription,
                      hintStyle: isArabic
                          ? GoogleFonts.cairo(color: Colors.white60)
                          : GoogleFonts.spaceGrotesk(color: Colors.white60),
                    ),
                    style: isArabic
                        ? GoogleFonts.cairo(color: Colors.white)
                        : GoogleFonts.spaceGrotesk(color: Colors.white),
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
                                  l10n.selectImage,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white60,
                                          fontSize: 12.sp,
                                        )
                                      : GoogleFonts.spaceGrotesk(
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
                      l10n.uploadImage,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )
                          : GoogleFonts.spaceGrotesk(
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
                      l10n.cancelButton,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
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
                            l10n.addProductButton,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
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
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 29, 41, 57),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: l10n.enterFieldHint(label),
            hintStyle: isArabic
                ? GoogleFonts.cairo(color: Colors.white60)
                : GoogleFonts.spaceGrotesk(color: Colors.white60),
          ),
          style: isArabic
              ? GoogleFonts.cairo(color: Colors.white)
              : GoogleFonts.spaceGrotesk(color: Colors.white),
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
    final isArabic = LocalizationHelper.isArabic(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
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
                    style: isArabic
                        ? GoogleFonts.cairo(color: Colors.white)
                        : GoogleFonts.spaceGrotesk(color: Colors.white),
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
