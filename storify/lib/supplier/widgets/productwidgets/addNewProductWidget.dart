import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Addnewproductwidget extends StatefulWidget {
  final Function() onCancel;
  final Function(Map<String, dynamic>) onAddProduct;

  const Addnewproductwidget({
    super.key,
    required this.onCancel,
    required this.onAddProduct,
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
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown selections
  String _selectedCategory = 'Electronics';
  String _selectedSupplier = 'TechSupply Inc.';
  String _status = 'Active';

  // Image handling
  bool _hasImage = false;

  // Fake categories and suppliers
  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food',
    'Home Decor',
    'Kitchenware',
    'Accessories',
    'Sports',
    'Toys',
  ];

  final List<String> _suppliers = [
    'TechSupply Inc.',
    'Fashion Forward',
    'HealthyEats Co.',
    'HomeStyles Ltd.',
    'GlobalImports',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a fake product with form data
      final newProduct = {
        'productId': 1000 + (DateTime.now().millisecondsSinceEpoch % 1000),
        'name': _nameController.text,
        'image': 'https://picsum.photos/200',
        'costPrice': double.parse(_costPriceController.text),
        'sellPrice': double.parse(_sellPriceController.text),
        'qty': int.parse(_quantityController.text),
        'categoryName': _selectedCategory,
        'availability': _status == 'Active',
        'description': _descriptionController.text,
      };

      // Pass the new product to parent
      widget.onAddProduct(newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildDropdown(
                  label: 'Category',
                  value: _selectedCategory,
                  items: _categories,
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
                _buildDropdown(
                  label: 'Status',
                  value: _status,
                  items: ['Active', 'Not Active'],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),

                // Supplier Dropdown
                _buildDropdown(
                  label: 'Supplier',
                  value: _selectedSupplier,
                  items: _suppliers,
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplier = value!;
                    });
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
                    image: _hasImage
                        ? const DecorationImage(
                            image: NetworkImage('https://picsum.photos/200'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _hasImage
                      ? null
                      : Icon(
                          Icons.image,
                          size: 40.sp,
                          color: Colors.white60,
                        ),
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
                  onPressed: () {
                    setState(() {
                      _hasImage = true;
                    });
                  },
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
                  onPressed: _submitForm,
                  child: Text(
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
