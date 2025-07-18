// product_detail_card.dart with authentication
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class ProductDetailCard extends StatefulWidget {
  final ProductDetail product;
  final int categoryID;
  final ValueChanged<ProductDetail> onUpdate;
  final VoidCallback? onDelete;

  const ProductDetailCard({
    Key? key,
    required this.product,
    required this.categoryID,
    required this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<ProductDetailCard> {
  bool _isEditing = false;
  bool _isDeleting = false;
  bool _isUpdating = false;
  String? _errorMessage;

  // Local copy of product values.
  late String _image;
  late String _name;
  late double _costPrice;
  late double _sellingPrice;
  dynamic
      _productID; // Store the ID as dynamic to match what comes from the API

  // Controllers for editable fields.
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _sellingController;

  @override
  void initState() {
    super.initState();
    _image = widget.product.image;
    _name = widget.product.name;
    _costPrice = widget.product.costPrice;
    _sellingPrice = widget.product.sellingPrice;
    _productID = widget.product.productID;

    // Debug log to check product ID
    debugPrint(
        'ProductDetailCard initialized with ID: ${widget.product.productID} (${widget.product.productID.runtimeType})');

    _nameController = TextEditingController(text: _name);
    _costController =
        TextEditingController(text: _costPrice.toStringAsFixed(2));
    _sellingController =
        TextEditingController(text: _sellingPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _sellingController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _errorMessage = null;

      if (_isEditing) {
        _saveChanges();
      } else {
        _isEditing = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Validate inputs
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = l10n.productNameCannotBeEmpty;
      });
      return;
    }

    final costPrice = double.tryParse(_costController.text);
    if (costPrice == null || costPrice < 0) {
      setState(() {
        _errorMessage = l10n.costPriceMustBeValid;
      });
      return;
    }

    final sellingPrice = double.tryParse(_sellingController.text);
    if (sellingPrice == null || sellingPrice < 0) {
      setState(() {
        _errorMessage = l10n.sellingPriceMustBeValid;
      });
      return;
    }

    // Update local state
    _name = name;
    _costPrice = costPrice;
    _sellingPrice = sellingPrice;

    // Create updated product object
    final updatedProduct = ProductDetail(
      productID: _productID,
      image: _image,
      name: _name,
      costPrice: _costPrice,
      sellingPrice: _sellingPrice,
    );

    // Set updating state
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    // Call API to update the product
    try {
      final success = await _updateProductInAPI(updatedProduct);
      if (success) {
        // This is the important part - update the widget.product reference
        widget.product.name = _name;
        widget.product.costPrice = _costPrice;
        widget.product.sellingPrice = _sellingPrice;
        widget.product.image = _image;

        // Then notify the parent
        widget.onUpdate(updatedProduct);

        setState(() {
          _isEditing = false;
          _isUpdating = false;
        });
      } else {
        setState(() {
          _isUpdating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "${l10n.failedToUpdate}: $e";
        _isUpdating = false;
      });
    }
  }

// Updated product update function with improved auth handling
  Future<bool> _updateProductInAPI(ProductDetail product) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    try {
      // Debug check for product ID before API call
      debugPrint(
          'Attempting update with productID: $_productID (${_productID.runtimeType})');

      if (_productID == null) {
        setState(() {
          _errorMessage = l10n.cannotUpdateProductWithoutId;
        });
        return false;
      }

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'name': product.name,
        'costPrice': product.costPrice,
        'sellPrice': product.sellingPrice,
      };

      // Add image if it's changed
      if (_image.startsWith('data:')) {
        final base64Image = _image.split(',')[1];
        requestBody['image'] = base64Image;
      }

      // Get auth headers including token
      final headers = await AuthService.getAuthHeaders();

      // Log complete request information
      debugPrint('PUT API Request:');
      debugPrint(
          'URL: https://finalproject-a5ls.onrender.com/product/$_productID');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${json.encode(requestBody)}');

      // Make the API call with auth headers
      final response = await http
          .put(
            Uri.parse(
                'https://finalproject-a5ls.onrender.com/product/$_productID'),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 1000));

      // Log response for debugging
      debugPrint('API Response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Try one more approach - some APIs expect the token in a different format

        final alternativeHeaders = {
          'Content-Type': 'application/json',
          'Authorization':
              headers['Authorization']?.replaceAll('Bearer ', '') ?? '',
        };

        debugPrint('Trying alternative header format: $alternativeHeaders');
        final retryResponse = await http
            .put(
              Uri.parse(
                  'https://finalproject-a5ls.onrender.com/product/$_productID'),
              headers: alternativeHeaders,
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        if (retryResponse.statusCode == 200) {
          debugPrint('Product updated successfully with alternative headers');
          return true;
        }

        // Unauthorized - token may be expired
        setState(() {
          _errorMessage = l10n.sessionExpiredLoginAgain;
        });

        // Optionally redirect to login

        return false;
      } else {
        try {
          final responseData = json.decode(response.body);
          setState(() {
            _errorMessage = responseData['message'] ??
                '${l10n.failedToUpdateProduct}: ${response.statusCode}';
          });
        } catch (e) {
          setState(() {
            _errorMessage =
                '${l10n.failedToUpdateProduct}: ${response.statusCode}';
          });
        }
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.errorUpdatingProduct}: $e';
      });
      return false;
    }
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
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _image = reader.result as String;
          });
        });
      }
    });
  }

  InputDecoration _buildInputDecoration(String label) {
    final isArabic = LocalizationHelper.isArabic(context);

    return InputDecoration(
      labelText: label,
      labelStyle: isArabic
          ? GoogleFonts.cairo(color: Colors.white70)
          : GoogleFonts.spaceGrotesk(color: Colors.white70),
      filled: true,
      fillColor: const Color.fromARGB(255, 54, 68, 88),
      border: const OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
    );
  }

  Future<void> _confirmDeletion() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: const Color.fromARGB(255, 28, 36, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.confirmDeletion,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            content: Text(
              l10n.areYouSureDeleteProduct,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.white70,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
            ),
            actions: [
              // Cancel button (positioned based on RTL)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Colors.white70, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                ),
              ),
              // Delete button
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Colors.red, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.delete,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      setState(() {
        _errorMessage = null;
        _isDeleting = true;
      });

      final success = await _deleteProductFromAPI();

      if (success) {
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      } else {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Updated delete product function with improved auth handling
  Future<bool> _deleteProductFromAPI() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    try {
      if (_productID == null) {
        setState(() {
          _errorMessage = l10n.cannotDeleteProductWithoutId;
          _isDeleting = false;
        });
        return false;
      }

      // Get auth headers with proper token format
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = l10n.authenticationRequired;
          _isDeleting = false;
        });

        return false;
      }

      // Create headers with explicit format
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      };

      debugPrint(
          'DELETE API Request: https://finalproject-a5ls.onrender.com/product/$_productID');
      debugPrint('Headers: $headers');

      final response = await http
          .delete(
            Uri.parse(
                'https://finalproject-a5ls.onrender.com/product/$_productID'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('API Response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // If token is rejected, try without Bearer prefix
        final alternativeHeaders = {
          'Content-Type': 'application/json',
          'Authorization': token,
          'Accept': 'application/json'
        };

        debugPrint('Trying alternative header format: $alternativeHeaders');
        final retryResponse = await http
            .delete(
              Uri.parse(
                  'https://finalproject-a5ls.onrender.com/product/$_productID'),
              headers: alternativeHeaders,
            )
            .timeout(const Duration(seconds: 15));

        if (retryResponse.statusCode == 200) {
          return true;
        }

        // If still failing, token is likely expired or invalid
        setState(() {
          _errorMessage = l10n.sessionExpiredLoginAgain;
          _isDeleting = false;
        });

        return false;
      } else {
        // Handle other error types
        setState(() {
          try {
            final responseData = json.decode(response.body);
            _errorMessage = responseData['message'] ??
                '${l10n.failedToDeleteProduct}: ${response.statusCode}';
          } catch (e) {
            _errorMessage =
                '${l10n.failedToDeleteProduct}: ${response.statusCode}';
          }
          _isDeleting = false;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.errorDeletingProduct}: $e';
        _isDeleting = false;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        color: const Color.fromARGB(255, 54, 68, 88),
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: _isDeleting
            ? Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: const Color.fromARGB(255, 105, 65, 198),
                      ),
                      SizedBox(height: 16),
                      Text(
                        l10n.deletingProduct,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message if there is one
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],

                    // Product Image with Edit overlay.
                    Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _image,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 90,
                                  width: 90,
                                  color: Colors.grey.shade700,
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white),
                                );
                              },
                            ),
                          ),
                          if (_isEditing)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(70, 36, 50, 69),
                                    shape: const CircleBorder(),
                                    fixedSize: Size(100.w, 50.h),
                                    elevation: 1,
                                  ),
                                  onPressed: _pickImage,
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Product name.
                    _isEditing
                        ? TextField(
                            controller: _nameController,
                            decoration: _buildInputDecoration(l10n.productName),
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            style: isArabic
                                ? GoogleFonts.cairo(color: Colors.white)
                                : GoogleFonts.spaceGrotesk(color: Colors.white),
                          )
                        : Text(
                            _name,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                          ),
                    const SizedBox(height: 12),
                    // Row with Cost Price and Selling Price.
                    Row(
                      children: [
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _costController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      _buildInputDecoration(l10n.costPrice),
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: isArabic
                                      ? GoogleFonts.cairo(color: Colors.white)
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white),
                                )
                              : Text(
                                  "${l10n.cost}: \$${_costPrice.toStringAsFixed(2)}",
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 16, color: Colors.white)
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 16, color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _sellingController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      _buildInputDecoration(l10n.sellingPrice),
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: isArabic
                                      ? GoogleFonts.cairo(color: Colors.white)
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white),
                                )
                              : Text(
                                  "${l10n.sell}: \$${_sellingPrice.toStringAsFixed(2)}",
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 16, color: Colors.white)
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row with Delete and Edit/Save buttons - RTL aware
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: isRtl
                            ? [
                                // For RTL: Edit/Save button first, then Delete
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(70, 36, 50, 69),
                                    side: const BorderSide(
                                        color:
                                            Color.fromARGB(255, 105, 65, 198),
                                        width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      _isUpdating ? null : _toggleEditing,
                                  child: _isUpdating
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isEditing ? l10n.save : l10n.edit,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  color: Colors.white)
                                              : GoogleFonts.spaceGrotesk(
                                                  fontSize: 16,
                                                  color: Colors.white),
                                        ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(
                                        color: Colors.red, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isEditing || _isUpdating
                                      ? null
                                      : _confirmDeletion,
                                  child: Text(
                                    l10n.delete,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            fontSize: 16,
                                            color: _isEditing || _isUpdating
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.red)
                                        : GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            color: _isEditing || _isUpdating
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.red),
                                  ),
                                ),
                              ]
                            : [
                                // For LTR: Delete button first, then Edit/Save
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(
                                        color: Colors.red, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isEditing || _isUpdating
                                      ? null
                                      : _confirmDeletion,
                                  child: Text(
                                    l10n.delete,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            fontSize: 16,
                                            color: _isEditing || _isUpdating
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.red)
                                        : GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            color: _isEditing || _isUpdating
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.red),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(70, 36, 50, 69),
                                    side: const BorderSide(
                                        color:
                                            Color.fromARGB(255, 105, 65, 198),
                                        width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      _isUpdating ? null : _toggleEditing,
                                  child: _isUpdating
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isEditing ? l10n.save : l10n.edit,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  color: Colors.white)
                                              : GoogleFonts.spaceGrotesk(
                                                  fontSize: 16,
                                                  color: Colors.white),
                                        ),
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
