// product_detail_card.dart
import 'dart:html' as html; // Only for Flutter Web image picking
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/categoryWidgets/model.dart';



class ProductDetailCard extends StatefulWidget {
  final ProductDetail product;
  final ValueChanged<ProductDetail> onUpdate;
  final VoidCallback? onDelete; // Called after deletion is confirmed.

  const ProductDetailCard({
    Key? key,
    required this.product,
    required this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<ProductDetailCard> {
  bool _isEditing = false;

  // Local copy of product values.
  late String _image;
  late String _name;
  late double _costPrice;
  late double _sellingPrice;
  late double _myPrice;

  // Controllers for editable fields.
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _sellingController;
  late TextEditingController _myPriceController;

  @override
  void initState() {
    super.initState();
    _image = widget.product.image;
    _name = widget.product.name;
    _costPrice = widget.product.costPrice;
    _sellingPrice = widget.product.sellingPrice;
    _myPrice = widget.product.myPrice;

    _nameController = TextEditingController(text: _name);
    _costController =
        TextEditingController(text: _costPrice.toStringAsFixed(2));
    _sellingController =
        TextEditingController(text: _sellingPrice.toStringAsFixed(2));
    _myPriceController =
        TextEditingController(text: _myPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _sellingController.dispose();
    _myPriceController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      if (_isEditing) {
        // Save changes.
        _name = _nameController.text;
        _costPrice = double.tryParse(_costController.text) ?? _costPrice;
        _sellingPrice =
            double.tryParse(_sellingController.text) ?? _sellingPrice;
        _myPrice = double.tryParse(_myPriceController.text) ?? _myPrice;
        final updatedProduct = ProductDetail(
          image: _image,
          name: _name,
          costPrice: _costPrice,
          sellingPrice: _sellingPrice,
          myPrice: _myPrice,
        );
        widget.onUpdate(updatedProduct);
      }
      _isEditing = !_isEditing;
    });
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
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.spaceGrotesk(color: Colors.white70),
      filled: true,
      fillColor: const Color.fromARGB(255, 54, 68, 88),
      // Remove default borders/underline.
      border: const OutlineInputBorder(borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
    );
  }

  Future<void> _confirmDeletion() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // require button press
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 28, 36, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Confirm Deletion",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this product?",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
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
                "Cancel",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
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
                "Delete",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (result == true) {
      // Call deletion callback.
      if (widget.onDelete != null) {
        widget.onDelete!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 54, 68, 88),
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    decoration: _buildInputDecoration("Product Name"),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  )
                : Text(
                    _name,
                    style: GoogleFonts.spaceGrotesk(
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _buildInputDecoration("Cost Price"),
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        )
                      : Text(
                          "Cost: \$${_costPrice.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, color: Colors.white),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _sellingController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _buildInputDecoration("Selling Price"),
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        )
                      : Text(
                          "Sell: \$${_sellingPrice.toStringAsFixed(2)}",
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // My Price field.
            _isEditing
                ? TextField(
                    controller: _myPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _buildInputDecoration("My Price"),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  )
                : Text(
                    "My Price: \$${_myPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, color: Colors.white),
                  ),
            const SizedBox(height: 12),
            // Row with Delete and Edit/Save buttons.
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _confirmDeletion,
                    child: Text(
                      "Delete",
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, color: Colors.red),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(70, 36, 50, 69),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 105, 65, 198), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _toggleEditing,
                    child: Text(
                      _isEditing ? "Save" : "Edit",
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
