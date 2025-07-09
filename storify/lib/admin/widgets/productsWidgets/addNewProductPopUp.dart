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
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Debug debugprint the JSON structure
    debugPrint('Parsing supplier JSON: $json');

    return Supplier(
      id: json['id'] ?? 0,
      name: json['user']?['name'] ?? json['name'] ?? 'Unknown Supplier',
    );
  }

  String _getLocalizedErrorMessage(String errorKey, AppLocalizations l10n) {
    switch (errorKey) {
      case 'NOT_AUTHORIZED_TO_ACCESS_FEATURE':
        return l10n.notAuthorizedToAccessFeature;
      case 'FAILED_TO_LOAD_SUPPLIERS':
        return l10n.notAuthorizedToAccessFeature;
      case 'NETWORK_ERROR':
        return l10n.networkError;
      default:
        return errorKey; // Return the key if no translation found
    }
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
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _lowStockController =
      TextEditingController(text: '10'); // Default value
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
  Set<int> _selectedSupplierIds =
      <int>{}; // Changed to Set for multiple selection

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

      debugPrint('Suppliers API Response Status: ${response.statusCode}');
      debugPrint('Suppliers API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['suppliers'] != null) {
          setState(() {
            _suppliers = (data['suppliers'] as List)
                .map((supplier) => Supplier.fromJson(supplier))
                .toList();
          });

          // Debug: Print supplier IDs
          debugPrint('Fetched suppliers:');
          for (var supplier in _suppliers) {
            debugPrint('ID: ${supplier.id}, Name: ${supplier.name}');
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _errorMessage = 'NOT_AUTHORIZED_TO_ACCESS_FEATURE';
        });
      } else {
        setState(() {
          _errorMessage = 'FAILED_TO_LOAD_SUPPLIERS';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'NETWORK_ERROR';
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
            debugPrint(
                "Loaded ${_categories.length} categories"); // Debug debugprint
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint(
            'Not authorized to fetch categories: ${response.statusCode}');
        // We don't set error message here as we'll show it from suppliers fetch
      } else {
        // If categories can't be loaded, we can still continue
        debugPrint('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (!_formKey.currentState!.validate()) {
      // If validation fails
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectCategory)),
      );
      return;
    }

    if (_selectedSupplierIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAtLeastOneSupplier)),
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
        throw Exception(l10n.authenticationTokenRequired);
      }

      // Create a multipart request for the product
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://finalproject-a5ls.onrender.com/product/add'),
      );

      // Add token header - note that the API expects 'token', not 'Authorization'
      request.headers['token'] = token;

      // Add all product data as form fields
      request.fields['name'] = _nameController.text; // Added name field
      request.fields['costPrice'] = _costPriceController.text;
      request.fields['sellPrice'] = _sellPriceController.text;
      request.fields['quantity'] = _quantityController.text;
      request.fields['categoryId'] = _selectedCategoryId.toString();
      request.fields['status'] = _status;

      // Add unit and lowStock fields properly
      if (_unitController.text.isNotEmpty) {
        request.fields['unit'] = _unitController.text;
        debugPrint('Adding unit field: ${_unitController.text}'); // Debug
      }

      if (_lowStockController.text.isNotEmpty) {
        request.fields['lowStock'] = _lowStockController.text;
        debugPrint(
            'Adding lowStock field: ${_lowStockController.text}'); // Debug
      }

      // Add multiple suppliers using the correct array format for multipart
      final supplierIdsList = _selectedSupplierIds.toList();

      debugPrint('Selected supplier IDs: $supplierIdsList');

      // Method 1: Try indexed field names (supplierIds[0], supplierIds[1], etc.)
      for (int i = 0; i < supplierIdsList.length; i++) {
        request.fields['supplierIds[$i]'] = supplierIdsList[i].toString();
      }

      // Debug debugprint all fields
      debugPrint('All request fields: ${request.fields}');
      debugPrint(
          'All request files: ${request.files.map((f) => '${f.field}: ${f.length} bytes').toList()}');

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

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Product added successfully
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.productAddedSuccessfully)),
          );
        }
      } else if (response.statusCode == 400 &&
          (response.body.contains('must be an array') ||
              response.body.contains('must be a number'))) {
        // Try alternative approach - bracket notation
        debugPrint('Retrying with bracket notation format...');

        // Create a new request with bracket notation
        final retryRequest = http.MultipartRequest(
          'POST',
          Uri.parse('https://finalproject-a5ls.onrender.com/product/add'),
        );

        retryRequest.headers['token'] = token;

        // Add all the same fields
        retryRequest.fields['name'] = _nameController.text;
        retryRequest.fields['costPrice'] = _costPriceController.text;
        retryRequest.fields['sellPrice'] = _sellPriceController.text;
        retryRequest.fields['quantity'] = _quantityController.text;
        retryRequest.fields['categoryId'] = _selectedCategoryId.toString();
        retryRequest.fields['status'] = _status;
        retryRequest.fields['unit'] = _unitController.text;
        retryRequest.fields['lowStock'] = _lowStockController.text;

        // Try bracket notation for suppliers
        for (int supplierId in supplierIdsList) {
          retryRequest.fields.addAll({'supplierIds[]': supplierId.toString()});
        }

        // Add optional fields
        if (_barcodeController.text.isNotEmpty) {
          retryRequest.fields['barcode'] = _barcodeController.text;
        }
        if (_prodDate != null) {
          retryRequest.fields['prodDate'] =
              DateFormat('yyyy-MM-dd').format(_prodDate!);
        }
        if (_expDate != null) {
          retryRequest.fields['expDate'] =
              DateFormat('yyyy-MM-dd').format(_expDate!);
        }
        if (_descriptionController.text.isNotEmpty) {
          retryRequest.fields['description'] = _descriptionController.text;
        }

        // Add image if exists
        if (_imageFile != null) {
          final reader = html.FileReader();
          final completer = Completer<List<int>>();
          reader.onLoad.listen((event) {
            final result = reader.result;
            if (result is String) {
              final bytes = base64.decode(result.split(',')[1]);
              completer.complete(bytes);
            } else {
              completer.completeError('Failed to read file as data URL');
            }
          });
          reader.onError.listen((event) {
            completer.completeError('Error reading file: ${reader.error}');
          });
          reader.readAsDataUrl(_imageFile!);
          final bytes = await completer.future;
          final imageFile = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _imageFile!.name,
            contentType: MediaType.parse(_imageFile!.type),
          );
          retryRequest.files.add(imageFile);
        }

        debugPrint('Retry request fields: ${retryRequest.fields}');

        // Send retry request
        final retryStreamedResponse = await retryRequest.send();
        final retryResponse =
            await http.Response.fromStream(retryStreamedResponse);

        debugPrint('Retry response status: ${retryResponse.statusCode}');
        debugPrint('Retry response body: ${retryResponse.body}');

        if (retryResponse.statusCode == 201 ||
            retryResponse.statusCode == 200) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.productAddedSuccessfully)),
            );
          }
          return;
        } else {
          String errorMessage =
              l10n.failedToAddProduct(retryResponse.statusCode.toString());
          try {
            final errorData = json.decode(retryResponse.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {}
          throw Exception(errorMessage);
        }
      } else if (response.statusCode == 404 &&
          response.body.contains('supplier IDs were not found')) {
        // Specific error for invalid supplier IDs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.selectedSuppliersNotFound),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: l10n.refreshSuppliers,
                onPressed: () {
                  _fetchSuppliers();
                },
              ),
            ),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Unauthorized access
        throw Exception(l10n.notAuthorizedToAddProducts);
      } else {
        // Error adding product
        String errorMessage =
            l10n.failedToAddProduct(response.statusCode.toString());
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Get localized status options
    final List<String> statusOptions = [l10n.active, l10n.notActive];
    final List<String> statusValues = ['Active', 'NotActive'];

    return Dialog(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 900.w, // Increased width to accommodate new fields
        constraints: BoxConstraints(maxHeight: 800.h), // Increased height
        padding: EdgeInsets.all(24.w),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text("error"))
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
                                l10n.addNewProduct,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
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
                                label: l10n.productName,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.pleaseEnterProductName;
                                  }
                                  return null;
                                },
                              ),

                              // Category Dropdown
                              _buildDropdown<Category>(
                                label: l10n.category,
                                items: _categories,
                                displayProperty: (category) => category.name,
                                valueProperty: (category) => category.id,
                                value: _selectedCategoryId,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                              ),

                              // Cost Price
                              _buildTextField(
                                controller: _costPriceController,
                                label: l10n.costPrice,
                                keyboardType: TextInputType.number,
                                isRtl: isRtl,
                                isArabic: isArabic,
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
                                isRtl: isRtl,
                                isArabic: isArabic,
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

                              // Quantity
                              _buildTextField(
                                controller: _quantityController,
                                label: l10n.quantity,
                                keyboardType: TextInputType.number,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.pleaseEnterQuantity;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return l10n.pleaseEnterValidNumber;
                                  }
                                  return null;
                                },
                              ),

                              // Unit (New Field)
                              _buildTextField(
                                controller: _unitController,
                                label: l10n.unit,
                                hintText: l10n.unitHint,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.pleaseEnterUnit;
                                  }
                                  return null;
                                },
                              ),

                              // Low Stock (New Field)
                              _buildTextField(
                                controller: _lowStockController,
                                label: l10n.lowStockThreshold,
                                keyboardType: TextInputType.number,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.pleaseEnterLowStockThreshold;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return l10n.pleaseEnterValidNumber;
                                  }
                                  return null;
                                },
                              ),

                              // Status Dropdown
                              _buildDropdown<String>(
                                label: l10n.status,
                                items: statusOptions,
                                displayProperty: (status) => status,
                                valueProperty: (status) =>
                                    statusValues[statusOptions.indexOf(status)],
                                value: _status,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                onChanged: (value) {
                                  setState(() {
                                    _status = value!;
                                  });
                                },
                              ),

                              // Barcode (Optional)
                              _buildTextField(
                                controller: _barcodeController,
                                label: l10n.barcodeOptional,
                                isRtl: isRtl,
                                isArabic: isArabic,
                              ),

                              // Production Date (Optional)
                              _buildDatePicker(
                                label: l10n.productionDateOptional,
                                value: _prodDate,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                onChanged: (date) {
                                  setState(() {
                                    _prodDate = date;
                                  });
                                },
                              ),

                              // Expiry Date (Optional)
                              _buildDatePicker(
                                label: l10n.expiryDateOptional,
                                value: _expDate,
                                isRtl: isRtl,
                                isArabic: isArabic,
                                onChanged: (date) {
                                  setState(() {
                                    _expDate = date;
                                  });
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // Suppliers (Multi-select)
                          _buildMultiSelectSuppliers(isArabic, isRtl),

                          SizedBox(height: 16.h),

                          // Description
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.description,
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
                                textAlign:
                                    isRtl ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 36, 50, 69),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: l10n.enterProductDescription,
                                  hintStyle: isArabic
                                      ? GoogleFonts.cairo(color: Colors.white60)
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white60),
                                ),
                                style: isArabic
                                    ? GoogleFonts.cairo(color: Colors.white)
                                    : GoogleFonts.spaceGrotesk(
                                        color: Colors.white),
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
                                l10n.addProduct,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
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

  Widget _buildMultiSelectSuppliers(bool isArabic, bool isRtl) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.suppliersRequired,
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
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 36, 50, 69),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectSuppliersForProduct,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
              ),
              SizedBox(height: 12.h),
              if (_suppliers.isEmpty)
                Text(
                  l10n.noSuppliersAvailable,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white60,
                          fontSize: 14.sp,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white60,
                          fontSize: 14.sp,
                        ),
                )
              else
                Container(
                  constraints: BoxConstraints(maxHeight: 200.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _suppliers.map((supplier) {
                        final isSelected =
                            _selectedSupplierIds.contains(supplier.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedSupplierIds.add(supplier.id);
                              } else {
                                _selectedSupplierIds.remove(supplier.id);
                              }
                            });
                          },
                          title: Text(
                            '${supplier.name} (${l10n.idLabel}: ${supplier.id})',
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                          ),
                          controlAffinity: isRtl
                              ? ListTileControlAffinity.trailing
                              : ListTileControlAffinity.leading,
                          activeColor: const Color.fromARGB(255, 105, 65, 198),
                          checkColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_selectedSupplierIds.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  l10n.selectedSuppliersCount(
                      _selectedSupplierIds.length.toString()),
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: _selectedSupplierIds.map((supplierId) {
                    final supplier =
                        _suppliers.firstWhere((s) => s.id == supplierId);
                    return Chip(
                      label: Text(
                        '${supplier.name} (${supplier.id})',
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                      ),
                      deleteIcon:
                          Icon(Icons.close, size: 16.sp, color: Colors.white),
                      onDeleted: () {
                        setState(() {
                          _selectedSupplierIds.remove(supplierId);
                        });
                      },
                      backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isRtl,
    required bool isArabic,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
  }) {
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
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 36, 50, 69),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: hintText ?? label,
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    required bool isRtl,
    required bool isArabic,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
                      : l10n.selectDate,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: value != null ? Colors.white : Colors.white60,
                        )
                      : GoogleFonts.spaceGrotesk(
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
    required bool isRtl,
    required bool isArabic,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
                          l10n.noItemsAvailable,
                          style: isArabic
                              ? GoogleFonts.cairo(color: Colors.white60)
                              : GoogleFonts.spaceGrotesk(color: Colors.white60),
                        ),
                      )
                    ]
                  : items.map((T item) {
                      return DropdownMenuItem<dynamic>(
                        value: valueProperty(item),
                        child: Text(
                          displayProperty(item),
                          style: isArabic
                              ? GoogleFonts.cairo(color: Colors.white)
                              : GoogleFonts.spaceGrotesk(color: Colors.white),
                        ),
                      );
                    }).toList(),
              hint: Text(
                l10n.selectItem(label),
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white60)
                    : GoogleFonts.spaceGrotesk(color: Colors.white60),
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
    _unitController.dispose();
    _lowStockController.dispose();
    _descriptionController.dispose();

    // Release object URLs when disposing
    if (_imagePreviewUrl != null) {
      html.Url.revokeObjectUrl(_imagePreviewUrl!);
    }

    super.dispose();
  }
}
