import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';

import 'package:storify/admin/widgets/productsWidgets/RequestedProductModel.dart';

class RequestedProductDetail extends StatefulWidget {
  final RequestedProductModel product;

  const RequestedProductDetail({
    super.key,
    required this.product,
  });

  @override
  State<RequestedProductDetail> createState() => _RequestedProductDetailState();
}

class _RequestedProductDetailState extends State<RequestedProductDetail> {
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();
  RequestedProductModel? _updatedProduct;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Process the request (accept or decline)
  Future<void> _processRequest(String action) async {
    setState(() {
      _isLoading = true;
    });

    // Get the admin note if provided
    final adminNote = _noteController.text.trim().isNotEmpty 
        ? _noteController.text.trim() 
        : null;

    final status = action == 'accept' ? 'Accepted' : 'Declined';

    try {
      // Get auth headers from AuthService
      final headers = await AuthService.getAuthHeaders();
      // Add Content-Type to headers
      headers['Content-Type'] = 'application/json';
      
      print('🔄 Processing request for product ${widget.product.id}: $status');
      print('📤 Request headers: $headers');
      
      final response = await http.patch(
        Uri.parse('https://finalproject-a5ls.onrender.com/request-product/${widget.product.id}/status'),
        headers: headers,
        body: json.encode({
          'status': status,
          'adminNote': adminNote,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['productRequest'] != null) {
          setState(() {
            _updatedProduct = RequestedProductModel.fromJson(data['productRequest']);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product request has been $status'),
              backgroundColor: status == 'Accepted' 
                  ? Colors.green 
                  : Colors.red,
            ),
          );

          // Return to previous screen after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop(_updatedProduct);
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process request: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the updated product if available, otherwise use the original
    final product = _updatedProduct ?? widget.product;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        title: Text(
          'Product Request Details',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(_updatedProduct),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 105, 65, 198),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product header section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: product.image != null
                            ? Image.network(
                                product.image!,
                                width: 200.w,
                                height: 200.h,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200.w,
                                    height: 200.h,
                                    color: Colors.grey.shade800,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 64.sp,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 200.w,
                                height: 200.h,
                                color: Colors.grey.shade800,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white70,
                                  size: 64.sp,
                                ),
                              ),
                      ),
                      SizedBox(width: 24.w),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildInfoRow('ID', '${product.id}'),
                            _buildInfoRow('Barcode', product.barcode),
                            _buildInfoRow('Category', product.category.categoryName),
                            _buildInfoRow('Cost Price', '\$${product.costPrice.toStringAsFixed(2)}'),
                            _buildInfoRow('Sell Price', '\$${product.sellPrice.toStringAsFixed(2)}'),
                            SizedBox(height: 16.h),
                            _buildStatusPill(product.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Supplier information section
                  _buildSectionHeader('Supplier Information'),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Name', product.supplier.user.name),
                        _buildInfoRow('Email', product.supplier.user.email),
                        _buildInfoRow('ID', '${product.supplier.id}'),
                        _buildInfoRow('Account Balance', product.supplier.accountBalance),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Product details section
                  _buildSectionHeader('Product Details'),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.description != null && product.description!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                product.description!,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        _buildInfoRow('Request Date', '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}'),
                        if (product.warranty != null)
                          _buildInfoRow('Warranty', product.warranty!),
                        if (product.prodDate != null)
                          _buildInfoRow('Production Date', '${product.prodDate!.day}/${product.prodDate!.month}/${product.prodDate!.year}'),
                        if (product.expDate != null)
                          _buildInfoRow('Expiry Date', '${product.expDate!.day}/${product.expDate!.month}/${product.expDate!.year}'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Admin note section if there is one
                  if (product.adminNote != null && product.adminNote!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Admin Note'),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 36, 50, 69),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            product.adminNote!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  
                  // Action buttons (only show if status is Pending)
                  if (product.status == 'Pending')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Actions'),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 36, 50, 69),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Optional admin note input
                              Text(
                                'Admin Note (Optional)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: _noteController,
                                maxLines: 3,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color.fromARGB(255, 29, 41, 57),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Add a note to the supplier...',
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              
                              // Accept/Decline buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      onPressed: () => _processRequest('decline'),
                                      child: Text(
                                        'Decline',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      onPressed: () => _processRequest('accept'),
                                      child: Text(
                                        'Accept',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build status pill
  Widget _buildStatusPill(String status) {
    late Color bgColor;
    
    switch (status) {
      case "Pending":
        bgColor = Colors.amber; // amber/yellow for pending
        break;
      case "Accepted":
        bgColor = const Color.fromARGB(178, 0, 224, 116); // green for accepted
        break;
      case "Declined":
        bgColor = const Color.fromARGB(255, 229, 62, 62); // red for declined
        break;
      default:
        bgColor = Colors.grey; // default
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
  }
}