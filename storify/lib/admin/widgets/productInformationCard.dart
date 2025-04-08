import 'dart:html' as html; // only for Flutter Web image picking
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/product_item_Model.dart';

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

  // Local copy of product values for editing.
  late String _imageUrl;
  late String _productName;
  late double _price;
  late String _category;
  late bool _isActive;

  // Controllers for editable fields.
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController; // For demo using text field

  // GlobalKey for the drop area container.
  final GlobalKey _dropAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.product.image;
    _productName = widget.product.name;
    _price = widget.product.price;
    _category = widget.product.category;
    _isActive = widget.product.availability;
    _nameController = TextEditingController(text: _productName);
    _priceController = TextEditingController(text: _price.toStringAsFixed(2));
    _categoryController = TextEditingController(text: _category);

    // Add HTML drop listeners after the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextObj = _dropAreaKey.currentContext;
      if (contextObj != null) {
        // Obtain the underlying HTML element for the drop area.
        // Note: This is a hacky way; it relies on internal implementation.
        try {
          final htmlElement = (contextObj.findRenderObject() as dynamic)
              .debugCreator
              .element as html.Element;
          // Prevent default dragover events.
          htmlElement.addEventListener('dragover', (html.Event event) {
            event.preventDefault();
          });
          // Handle file drops.
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      if (_isEditing) {
        // Save changes from controllers.
        _productName = _nameController.text;
        _price = double.tryParse(_priceController.text) ?? _price;
        _category = _categoryController.text;
        // Create an updated product.
        final updatedProduct = ProductItemInformation(
          image: _imageUrl,
          name: _productName,
          price: _price,
          qty: widget.product.qty, // unchanged in this demo
          category: _category,
          availability: _isActive,
        );
        widget.onUpdate(updatedProduct);
      }
      _isEditing = !_isEditing;
    });
  }

  // This function remains for onTap image selection.
  Future<void> _pickImage() async {
    if (!_isEditing) return;
    print("Pick image triggered");
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        print("File selected");
        final html.File file = files.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _imageUrl = reader.result as String;
          });
          print("Image updated via click");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(20), // Increased radius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row and Edit/Save button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Product Information",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22, // Bigger title font
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // slightly rounded
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16), // larger button
                ),
                onPressed: _toggleEditing,
                child: Text(
                  _isEditing ? "Save" : "Edit",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, // larger button text
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Drop area and image.
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Product Image with both tap and drop support.
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        key: _dropAreaKey, // Used for attaching drop listeners.
                        child: Stack(
                          children: [
                            // Image with onTap (for file selection).
                            InkWell(
                              onTap: _pickImage,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Overlay for editing (also taps trigger image pick).
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
                                            size: 36, // larger icon
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Drop or Import",
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 16, // bigger text
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
                  ),
                  const SizedBox(width: 28),
                  // Right: Product details.
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          title: "Price",
                          child: _isEditing
                              ? TextField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                                  decoration: _inputDecoration("Enter price"),
                                )
                              : Text(
                                  "\$${_price.toStringAsFixed(2)}",
                                  style: _labelStyle(),
                                ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          title: "Category",
                          child: _isEditing
                              ? TextField(
                                  controller: _categoryController,
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                                  decoration:
                                      _inputDecoration("Enter category"),
                                )
                              : Text(
                                  _category,
                                  style: _labelStyle(),
                                ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          title: "Status",
                          child: _isEditing
                              ? DropdownButtonFormField<bool>(
                                  value: _isActive,
                                  dropdownColor:
                                      const Color.fromARGB(255, 36, 50, 69),
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                                  decoration: _inputDecorationDropdown(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: true, child: Text("Active")),
                                    DropdownMenuItem(
                                        value: false, child: Text("UnActive")),
                                  ],
                                  onChanged: (bool? value) {
                                    if (value != null) {
                                      setState(() {
                                        _isActive = value;
                                      });
                                    }
                                  },
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isActive
                                        ? const Color.fromARGB(178, 0, 224, 116)
                                        : const Color.fromARGB(
                                            255, 229, 62, 62),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _isActive ? "Active" : "UnActive",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper for building each detail row.
  Widget _buildDetailRow({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.spaceGrotesk(
      fontSize: 16,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
  }
}
