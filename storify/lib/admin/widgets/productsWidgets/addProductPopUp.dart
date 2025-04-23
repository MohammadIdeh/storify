// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';

// class AddProductPopup extends StatefulWidget {
//   final Function? onProductAdded;

//   const AddProductPopup({Key? key, this.onProductAdded}) : super(key: key);

//   @override
//   State<AddProductPopup> createState() => _AddProductPopupState();
// }

// class _AddProductPopupState extends State<AddProductPopup> {
//   final _formKey = GlobalKey<FormState>();
  
//   // Text controllers for each field
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _costPriceController = TextEditingController();
//   final TextEditingController _sellPriceController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _barcodeController = TextEditingController();
//   final TextEditingController _warrantyController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
  
//   // Date controllers
//   DateTime? _prodDate;
//   DateTime? _expDate;
  
//   // Selected values
//   String _status = "Active";
//   int? _selectedCategoryId;
//   int? _selectedSupplierId;
  
//   // Lists for dropdowns
//   List<Map<String, dynamic>> _categories = [];
//   List<Map<String, dynamic>> _suppliers = [];
  
//   // Image handling
//   File? _imageFile;
//   String? _uploadedImageUrl;
//   bool _isUploading = false;
  
//   // Loading states
//   bool _isLoading = true;
//   bool _isSaving = false;
//   String _errorMessage = '';
  
//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }
  
//   Future<void> _fetchData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // Fetch categories (replace with your actual API endpoint)
//       final categoriesResponse = await http.get(
//         Uri.parse('https://finalproject-a5ls.onrender.com/category/all'),
//       );
      
//       if (categoriesResponse.statusCode == 200) {
//         final List<dynamic> categoriesData = json.decode(categoriesResponse.body);
//         _categories = categoriesData.map((cat) => {
//           'id': cat['categoryID'],
//           'name': cat['categoryName'],
//         }).toList();
        
//         if (_categories.isNotEmpty) {
//           _selectedCategoryId = _categories[0]['id'];
//         }
//       }
      
//       // Fetch suppliers (replace with your actual API endpoint)
//       final suppliersResponse = await http.get(
//         Uri.parse('https://finalproject-a5ls.onrender.com/supplier/all'),
//       );
      
//       if (suppliersResponse.statusCode == 200) {
//         final List<dynamic> suppliersData = json.decode(suppliersResponse.body);
//         _suppliers = suppliersData.map((supplier) => {
//           'id': supplier['id'],
//           'name': supplier['user']['name'],
//           'email': supplier['user']['email'],
//         }).toList();
        
//         if (_suppliers.isNotEmpty) {
//           _selectedSupplierId = _suppliers[0]['id'];
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to load data: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
  
//   Future<void> _pickImage() async {
//     final ImagePicker _picker = ImagePicker();
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
//     if (image != null) {
//       setState(() {
//         _imageFile = File(image.path);
//       });
      
//       // Upload the image
//       await _uploadImage();
//     }
//   }
  
//   Future<void> _uploadImage() async {
//     if (_imageFile == null) return;
    
//     setState(() {
//       _isUploading = true;
//     });
    
//     try {
//       // Create a multipart request for image upload
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('https://finalproject-a5ls.onrender.com/upload/product-image'),
//       );
      
//       // Add the file to the request
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'image',
//           _imageFile!.path,
//         ),
//       );
      
//       // Send the request
//       var response = await request.send();
//       var responseData = await response.stream.bytesToString();
//       var jsonResponse = json.decode(responseData);
      
//       if (response.statusCode == 200) {
//         setState(() {
//           _uploadedImageUrl = jsonResponse['url'];
//           _isUploading = false;
//         });
//       } else {
//         setState(() {
//           _errorMessage = 'Failed to upload image: ${jsonResponse['message'] ?? 'Unknown error'}';
//           _isUploading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error uploading image: ${e.toString()}';
//         _isUploading = false;
//       });
//     }
//   }
  
//   Future<void> _saveProduct() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     if (_uploadedImageUrl == null && _imageFile != null) {
//       // If image is selected but not yet uploaded, wait for upload
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please wait for image upload to complete')),
//       );
//       return;
//     }
    
//     setState(() {
//       _isSaving = true;
//       _errorMessage = '';
//     });
    
//     try {
//       final Map<String, dynamic> productData = {
//         'name': _nameController.text,
//         'costPrice': double.parse(_costPriceController.text),
//         'sellPrice': double.parse(_sellPriceController.text),
//         'quantity': int.parse(_quantityController.text),
//         'categoryId': _selectedCategoryId,
//         'status': _status,
//         'description': _descriptionController.text,
//         'suppliers': [
//           {
//             'id': _selectedSupplierId,
//           }
//         ],
//       };
      
//       // Add optional fields if they have values
//       if (_barcodeController.text.isNotEmpty) {
//         productData['barcode'] = _barcodeController.text;
//       }
      
//       if (_warrantyController.text.isNotEmpty) {
//         productData['warranty'] = _warrantyController.text;
//       }
      
//       if (_prodDate != null) {
//         productData['prodDate'] = _prodDate!.toIso8601String();
//       }
      
//       if (_expDate != null) {
//         productData['expDate'] = _expDate!.toIso8601String();
//       }
      
//       if (_uploadedImageUrl != null) {
//         productData['image'] = _uploadedImageUrl;
//       }
      
//       // Send the request to add product
//       final response = await http.post(
//         Uri.parse('https://finalproject-a5ls.onrender.com/product/add'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(productData),
//       );
      
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         // Product added successfully
//         if (widget.onProductAdded != null) {
//           widget.onProductAdded!();
//         }
        
//         Navigator.of(context).pop(true); // Close dialog and return success
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Product added successfully')),
//         );
//       } else {
//         final responseData = json.decode(response.body);
//         setState(() {
//           _errorMessage = 'Failed to add product: ${responseData['message'] ?? 'Unknown error'}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error saving product: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isSaving = false;
//       });
//     }
//   }
  
//   Future<void> _selectDate(BuildContext context, bool isProductionDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.dark(
//               primary: Color.fromARGB(255, 105, 65, 198),
//               onPrimary: Colors.white,
//               surface: Color.fromARGB(255, 36, 50, 69),
//               onSurface: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (picked != null) {
//       setState(() {
//         if (isProductionDate) {
//           _prodDate = picked;
//         } else {
//           _expDate = picked;
//         }
//       });
//     }
//   }
  
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _costPriceController.dispose();
//     _sellPriceController.dispose();
//     _quantityController.dispose();
//     _barcodeController.dispose();
//     _warrantyController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: const Color.fromARGB(255, 29, 41, 57),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         width: 600.w,
//         padding: EdgeInsets.all(24.w),
//         child: _isLoading
//             ? Center(
//                 child: CircularProgressIndicator(
//                   color: const Color.fromARGB(255, 105, 65, 198),
//                 ),
//               )
//             : SingleChildScrollView(
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Title and close button
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Add New Product',
//                             style: GoogleFonts.spaceGrotesk(
//                               fontSize: 24.sp,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.close, color: Colors.white),
//                             onPressed: () => Navigator.of(context).pop(),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 24.h),
                      
//                       // Error message if any
//                       if (_errorMessage.isNotEmpty)
//                         Container(
//                           padding: EdgeInsets.all(16.w),
//                           margin: EdgeInsets.only(bottom: 16.h),
//                           decoration: BoxDecoration(
//                             color: Colors.red.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             _errorMessage,
//                             style: GoogleFonts.spaceGrotesk(
//                               color: Colors.red,
//                             ),
//                           ),
//                         ),
                      
//                       // Image Upload Section
//                       Center(
//                         child: Column(
//                           children: [
//                             GestureDetector(
//                               onTap: _isUploading ? null : _pickImage,
//                               child: Container(
//                                 width: 120.w,
//                                 height: 120.h,
//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 36, 50, 69),
//                                   borderRadius: BorderRadius.circular(12),
//                                   image: _imageFile != null
//                                       ? DecorationImage(
//                                           image: FileImage(_imageFile!),
//                                           fit: BoxFit.cover,
//                                         )
//                                       : null,
//                                 ),
//                                 child: _imageFile == null
//                                     ? Icon(
//                                         Icons.add_a_photo,
//                                         color: Colors.white,
//                                         size: 40.sp,
//                                       )
//                                     : _isUploading
//                                         ? Center(
//                                             child: CircularProgressIndicator(
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                         : null,
//                               ),
//                             ),
//                             SizedBox(height: 8.h),
//                             Text(
//                               'Product Image',
//                               style: GoogleFonts.spaceGrotesk(
//                                 color: Colors.white,
//                                 fontSize: 14.sp,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 24.h),
                      
//                       // Form fields
//                       Row(
//                         children: [
//                           // Name field
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _nameController,
//                               label: 'Product Name',
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter product name';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Category dropdown
//                           Expanded(
//                             child: _buildDropdown(
//                               label: 'Category',
//                               value: _selectedCategoryId,
//                               items: _categories.map((category) {
//                                 return DropdownMenuItem<int>(
//                                   value: category['id'],
//                                   child: Text(category['name']),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   _selectedCategoryId = value;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.h),
                      
//                       // Price and quantity row
//                       Row(
//                         children: [
//                           // Cost price
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _costPriceController,
//                               label: 'Cost Price',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter cost price';
//                                 }
//                                 if (double.tryParse(value) == null) {
//                                   return 'Please enter a valid number';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Sell price
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _sellPriceController,
//                               label: 'Sell Price',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter sell price';
//                                 }
//                                 if (double.tryParse(value) == null) {
//                                   return 'Please enter a valid number';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Quantity
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _quantityController,
//                               label: 'Quantity',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter quantity';
//                                 }
//                                 if (int.tryParse(value) == null) {
//                                   return 'Please enter a valid number';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.h),
                      
//                       // Status and Supplier row
//                       Row(
//                         children: [
//                           // Status dropdown
//                           Expanded(
//                             child: _buildDropdown(
//                               label: 'Status',
//                               value: _status,
//                               items: ['Active', 'UnActive'].map((status) {
//                                 return DropdownMenuItem<String>(
//                                   value: status,
//                                   child: Text(status),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   _status = value!;
//                                 });
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Supplier dropdown
//                           Expanded(
//                             child: _buildDropdown(
//                               label: 'Supplier',
//                               value: _selectedSupplierId,
//                               items: _suppliers.map((supplier) {
//                                 return DropdownMenuItem<int>(
//                                   value: supplier['id'],
//                                   child: Text(supplier['name']),
//                                 );
//                               }).toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   _selectedSupplierId = value;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.h),
                      
//                       // Optional fields row
//                       Row(
//                         children: [
//                           // Barcode
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _barcodeController,
//                               label: 'Barcode (Optional)',
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Warranty
//                           Expanded(
//                             child: _buildTextField(
//                               controller: _warrantyController,
//                               label: 'Warranty (Optional)',
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.h),
                      
//                       // Date fields row
//                       Row(
//                         children: [
//                           // Production date
//                           Expanded(
//                             child: _buildDatePicker(
//                               label: 'Production Date (Optional)',
//                               value: _prodDate,
//                               onTap: () => _selectDate(context, true),
//                             ),
//                           ),
//                           SizedBox(width: 16.w),
//                           // Expiration date
//                           Expanded(
//                             child: _buildDatePicker(
//                               label: 'Expiration Date (Optional)',
//                               value: _expDate,
//                               onTap: () => _selectDate(context, false),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.h),
                      
//                       // Description field
//                       _buildTextField(
//                         controller: _descriptionController,
//                         label: 'Description',
//                         maxLines: 3,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter product description';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 24.h),
                      
//                       // Submit button
//                       Center(
//                         child: SizedBox(
//                           width: 200.w,
//                           height: 50.h,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color.fromARGB(255, 105, 65, 198),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: _isSaving ? null : _saveProduct,
//                             child: _isSaving
//                                 ? CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   )
//                                 : Text(
//                                     'Add Product',
//                                     style: GoogleFonts.spaceGrotesk(
//                                       fontSize: 16.sp,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }
  
//   // Helper methods to build form widgets
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     int maxLines = 1,
//     TextInputType keyboardType = TextInputType.text,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 14.sp,
//             fontWeight: FontWeight.w500,
//             color: Colors.white70,
//           ),
//         ),
//         SizedBox(height: 8.h),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           keyboardType: keyboardType,
//           validator: validator,
//           style: GoogleFonts.spaceGrotesk(
//             color: Colors.white,
//           ),
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: const Color.fromARGB(255, 36, 50, 69),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: 16.w,
//               vertical: 16.h,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             errorStyle: GoogleFonts.spaceGrotesk(
//               color: Colors.red,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildDropdown<T>({
//     required String label,
//     required T value,
//     required List<DropdownMenuItem<T>> items,
//     required void Function(T?) onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 14.sp,
//             fontWeight: FontWeight.w500,
//             color: Colors.white70,
//           ),
//         ),
//         SizedBox(height: 8.h),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           decoration: BoxDecoration(
//             color: const Color.fromARGB(255, 36, 50, 69),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<T>(
//               value: value,
//               items: items,
//               onChanged: onChanged,
//               dropdownColor: const Color.fromARGB(255, 36, 50, 69),
//               style: GoogleFonts.spaceGrotesk(
//                 color: Colors.white,
//               ),
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.white70,
//               ),
//               isExpanded: true,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildDatePicker({
//     required String label,
//     required DateTime? value,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.spaceGrotesk(
//             fontSize: 14.sp,
//             fontWeight: FontWeight.w500,
//             color: Colors.white70,
//           ),
//         ),
//         SizedBox(height: 8.h),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: 16.w,
//               vertical: 16.h,
//             ),
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 36, 50, 69),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   value != null
//                       ? '${value.day}/${value.month}/${value.year}'
//                       : 'Select Date',
//                   style: GoogleFonts.spaceGrotesk(
//                     color: value != null ? Colors.white : Colors.white54,
//                   ),
//                 ),
//                 Icon(
//                   Icons.calendar_today,
//                   color: Colors.white70,
//                   size: 20.sp,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }