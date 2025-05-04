import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';

// Define our OrderLineItem model for the items in an order
class OrderLineItem {
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double total;

  OrderLineItem({
    required this.name,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });
}

class Vieworder extends StatefulWidget {
  final OrderItem order;
  final bool isSupplierMode;

  const Vieworder({
    Key? key,
    required this.order,
    this.isSupplierMode = true,
  }) : super(key: key);

  @override
  State<Vieworder> createState() => _VieworderState();
}

class _VieworderState extends State<Vieworder> {
  late OrderItem _localOrder;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _noteController = TextEditingController();

  // Detailed order info
  Map<String, dynamic>? _orderDetails;

  // Line items
  List<OrderLineItem> _lineItems = [];

  // Pagination variables
  int _lineItemsCurrentPage = 1;
  final int _lineItemsPerPage = 7;

  // Flag to check if we're in customer mode
  bool get isCustomerOrder => !widget.isSupplierMode;

  @override
  void initState() {
    super.initState();
    _localOrder = widget.order;
    _fetchOrderDetails();
  }

  // Fetch appropriate order details based on mode
  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isSupplierMode) {
        await _fetchSupplierOrderDetails();
      } else {
        await _fetchCustomerOrderDetails();
      }
    } catch (e) {
      print("Error in fetch order details: $e");
      setState(() {
        _errorMessage = 'Error fetching order details: $e';
        _isLoading = false;
      });
    }
  }

  // Fetch supplier order details
  Future<void> _fetchSupplierOrderDetails() async {
    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();

      // Fetch order details
      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/supplierOrders/${widget.order.orderId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] == 'Order retrieved successfully') {
          final orderData = data['order'];
          print("Order data: $orderData"); // Debug

          // Extract totalCost directly
          double totalCost = 0.0;
          if (orderData['totalCost'] != null) {
            if (orderData['totalCost'] is num) {
              totalCost = (orderData['totalCost'] as num).toDouble();
            } else {
              totalCost =
                  double.tryParse(orderData['totalCost'].toString()) ?? 0.0;
            }
          }
          print("Extracted totalCost: $totalCost"); // Debug

          // Process items one by one
          List<OrderLineItem> processedItems = [];

          if (orderData['items'] != null &&
              orderData['items'] is List &&
              orderData['items'].isNotEmpty) {
            for (var item in orderData['items']) {
              final product = item['product'] ?? {};

              // Extract and convert fields
              double costPrice = 0.0;
              int quantity = 0;
              double subtotal = 0.0;

              // Process costPrice
              if (item['costPrice'] != null) {
                if (item['costPrice'] is num) {
                  costPrice = (item['costPrice'] as num).toDouble();
                } else {
                  costPrice =
                      double.tryParse(item['costPrice'].toString()) ?? 0.0;
                }
              }

              // Process quantity
              if (item['quantity'] != null) {
                if (item['quantity'] is num) {
                  quantity = (item['quantity'] as num).toInt();
                } else {
                  quantity = int.tryParse(item['quantity'].toString()) ?? 0;
                }
              }

              // Process subtotal
              if (item['subtotal'] != null) {
                if (item['subtotal'] is num) {
                  subtotal = (item['subtotal'] as num).toDouble();
                } else {
                  subtotal =
                      double.tryParse(item['subtotal'].toString()) ?? 0.0;
                }
              }

              print(
                  "Item: ${product['name']} - Price: $costPrice, Qty: $quantity, Total: $subtotal"); // Debug

              processedItems.add(OrderLineItem(
                name: product['name'] ?? 'Unknown Product',
                imageUrl: product['image'],
                unitPrice: costPrice,
                quantity: quantity,
                total: subtotal,
              ));
            }
          }

          setState(() {
            _orderDetails = orderData;
            _lineItems = processedItems;

            // Create a new order with the updated total amount
            _localOrder = OrderItem(
              orderId: widget.order.orderId,
              storeName: widget.order.storeName,
              phoneNo: widget.order.phoneNo,
              orderDate: widget.order.orderDate,
              totalProducts: widget.order.totalProducts,
              totalAmount: totalCost,
              status: widget.order.status,
              note: widget.order.note,
              supplierId: widget.order.supplierId,
              items: widget.order.items,
            );

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load order details: ${data['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load order details. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in fetch supplier order details: $e"); // Debug
      rethrow;
    }
  }

  // Fetch customer order details
// Update the _fetchCustomerOrderDetails method in the Vieworder class
  Future<void> _fetchCustomerOrderDetails() async {
    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();

      // Fetch order details
      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/${widget.order.orderId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("API Response: $responseData"); // Debug output

        // Extract the order data from the nested 'order' property
        final orderData = responseData['order'];
        if (orderData == null) {
          throw Exception('Order data not found in response');
        }

        print("Customer order data: $orderData"); // Debug output

        // Extract totalCost directly from the API response
        double totalCost = 0.0;
        if (orderData['totalCost'] != null) {
          if (orderData['totalCost'] is num) {
            totalCost = (orderData['totalCost'] as num).toDouble();
          } else {
            totalCost =
                double.tryParse(orderData['totalCost'].toString()) ?? 0.0;
          }
        }
        print("Total cost from API: $totalCost");

        // Process items
        List<OrderLineItem> processedItems = [];

        if (orderData['items'] != null && orderData['items'] is List) {
          final itemsList = orderData['items'] as List;
          print("Found ${itemsList.length} items");

          for (var item in itemsList) {
            // Get product information
            final product = item['product'] ?? {};
            final String productName = product['name'] ?? 'Unknown Product';
            final String? imageUrl = product['image'];

            // Extract price - note the capital 'P' in 'Price'
            double price = 0.0;
            if (item['Price'] != null) {
              // Capital 'P' as in your data
              price = item['Price'] is num
                  ? (item['Price'] as num).toDouble()
                  : double.tryParse(item['Price'].toString()) ?? 0.0;
            }

            // Extract quantity
            int quantity = 0;
            if (item['quantity'] != null) {
              quantity = item['quantity'] is num
                  ? (item['quantity'] as num).toInt()
                  : int.tryParse(item['quantity'].toString()) ?? 0;
            }

            // Extract subtotal
            double subtotal = 0.0;
            if (item['subtotal'] != null) {
              subtotal = item['subtotal'] is num
                  ? (item['subtotal'] as num).toDouble()
                  : double.tryParse(item['subtotal'].toString()) ?? 0.0;
            }

            print(
                "Item: $productName, Price: $price, Quantity: $quantity, Subtotal: $subtotal");

            // Create the line item
            processedItems.add(OrderLineItem(
              name: productName,
              imageUrl: imageUrl,
              unitPrice: price,
              quantity: quantity,
              total: subtotal,
            ));
          }
        }

        setState(() {
          _orderDetails = orderData;
          _lineItems = processedItems;

          // Create a new order with the updated total amount from API
          _localOrder = widget.order.copyWith(totalAmount: totalCost);

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load customer order details. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in fetch customer order details: $e"); // Debug error
      setState(() {
        _errorMessage = 'Error fetching customer order details: $e';
        _isLoading = false;
      });
    }
  }

  // Accept customer order
  Future<void> _acceptCustomerOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Create request body - only include note if it's not empty
      final Map<String, dynamic> requestBody = {
        'status': 'Accepted',
      };

      // Only add note field if it's not empty
      if (_noteController.text.isNotEmpty) {
        requestBody['note'] = _noteController.text;
      }

      // Update order status
      final response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/${widget.order.orderId}/status'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted successfully'),
            backgroundColor: const Color.fromARGB(178, 0, 224, 116),
          ),
        );

        // Refresh the entire screen with latest data

        // Only after refresh is complete, pass back the updated order to previous screen
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, _localOrder);
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to accept order. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accepting order: $e';
        _isLoading = false;
      });
    }
  }

  // Reject customer order
  Future<void> _rejectCustomerOrder() async {
    // Check if note is empty - require note for rejection
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a reason for rejecting this order'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop if note is empty
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Use the existing note from the text field (required)
      final response = await http.put(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/${widget.order.orderId}/status'),
        headers: headers,
        body: json.encode({
          'status': 'Rejected',
          'note': _noteController.text, // Required for rejection
        }),
      );

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order rejected successfully'),
            backgroundColor: const Color.fromARGB(255, 229, 62, 62),
          ),
        );

        // Refresh the entire screen with latest data

        // Only after refresh is complete, pass back the updated order to previous screen
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, _localOrder);
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to reject order. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error rejecting order: $e';
        _isLoading = false;
      });
    }
  }

  List<OrderLineItem> get _visibleLineItems {
    final totalItems = _lineItems.length;
    if (totalItems == 0) return [];

    final totalPages = (totalItems / _lineItemsPerPage).ceil();
    if (_lineItemsCurrentPage > totalPages && totalPages > 0) {
      _lineItemsCurrentPage = 1;
    }
    final startIndex = (_lineItemsCurrentPage - 1) * _lineItemsPerPage;
    int endIndex = startIndex + _lineItemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;
    return _lineItems.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _fetchOrderDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 105, 65, 198),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text(
                            'Go Back',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: "Back" button and "Order Details" with buttons.
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 29, 41, 57),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 1.5,
                                      color: Color.fromARGB(255, 47, 71, 82),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  fixedSize: Size(120.w, 50.h),
                                  elevation: 1,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, _localOrder);
                                },
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/back.svg',
                                      width: 18.w,
                                      height: 18.h,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Back',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color.fromARGB(
                                            255, 105, 123, 123),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20.w),
                              Text(
                                "Order Details",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      const Color.fromARGB(255, 246, 246, 246),
                                ),
                              ),
                              const Spacer(),
                              // Show action buttons based on mode
                              if (!widget
                                  .isSupplierMode) // Only for Customer mode
                                // "Print Invoice" button.
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    shape: RoundedRectangleBorder(
                                      side: const BorderSide(
                                        width: 1.5,
                                        color: Color.fromARGB(255, 47, 71, 82),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    fixedSize: Size(220.w, 50.h),
                                    elevation: 1,
                                  ),
                                  onPressed: () {
                                    // Print Invoice action placeholder.
                                  },
                                  child: Text(
                                    'Print Invoice',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color.fromARGB(
                                          255, 105, 123, 123),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Main content row: left (items table) + right (order details).
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side: Items table (flex = 2).
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30.r),
                                      topRight: Radius.circular(30.r),
                                      bottomRight: Radius.circular(30.r),
                                      bottomLeft: Radius.circular(30.r),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Items",
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      // Items table
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          dataRowColor: WidgetStateProperty
                                              .resolveWith<Color?>(
                                            (Set<WidgetState> states) =>
                                                Colors.transparent,
                                          ),
                                          headingRowColor:
                                              MaterialStateProperty.all<Color>(
                                            const Color.fromARGB(
                                                255, 47, 71, 82),
                                          ),
                                          border: TableBorder(
                                            horizontalInside: BorderSide(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          columnSpacing: 20.w,
                                          columns: [
                                            DataColumn(
                                              label: Text(
                                                "Image",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Item",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Unit Price",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Qty",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Total",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                          ],
                                          rows: _visibleLineItems.map((item) {
                                            // Pre-format all strings for display
                                            final String nameStr = item.name;
                                            final String unitPriceStr =
                                                "\$${item.unitPrice.toStringAsFixed(2)}";
                                            final String qtyStr =
                                                item.quantity.toString();
                                            final String totalStr =
                                                "\$${item.total.toStringAsFixed(2)}";

                                            return DataRow(
                                              cells: [
                                                // Image cell
                                                DataCell(
                                                  Container(
                                                    width: 40.w,
                                                    height: 40.h,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.r),
                                                    ),
                                                    child: item.imageUrl != null
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6.r),
                                                            child:
                                                                Image.network(
                                                              item.imageUrl!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Icon(
                                                                  Icons
                                                                      .image_not_supported_outlined,
                                                                  color: Colors
                                                                      .white54,
                                                                  size: 20.sp,
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons
                                                                .image_outlined,
                                                            color:
                                                                Colors.white54,
                                                            size: 20.sp,
                                                          ),
                                                  ),
                                                ),
                                                // Name cell
                                                DataCell(Text(
                                                  nameStr,
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                  ),
                                                )),
                                                // Unit price cell
                                                DataCell(Text(
                                                  unitPriceStr,
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                  ),
                                                )),
                                                // Quantity cell
                                                DataCell(Text(
                                                  qtyStr,
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                  ),
                                                )),
                                                // Total cell
                                                DataCell(Text(
                                                  totalStr,
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                  ),
                                                )),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                      // Pagination controls if more than one page
                                      if (_lineItems.length >
                                          _lineItemsPerPage) ...[
                                        SizedBox(height: 16.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_back_ios,
                                                color: Colors.white,
                                                size: 16.sp,
                                              ),
                                              onPressed:
                                                  _lineItemsCurrentPage > 1
                                                      ? () {
                                                          setState(() {
                                                            _lineItemsCurrentPage--;
                                                          });
                                                        }
                                                      : null,
                                            ),
                                            Text(
                                              "Page $_lineItemsCurrentPage of ${(_lineItems.length / _lineItemsPerPage).ceil()}",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.white,
                                                size: 16.sp,
                                              ),
                                              onPressed: _lineItemsCurrentPage <
                                                      (_lineItems.length /
                                                              _lineItemsPerPage)
                                                          .ceil()
                                                  ? () {
                                                      setState(() {
                                                        _lineItemsCurrentPage++;
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ],

                                      SizedBox(height: 20.h),
                                      // Only Grand Total
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: 6.h),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Grand Total: ",
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                "\$" +
                                                    _localOrder.totalAmount
                                                        .toStringAsFixed(2),
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 20.w),
                              // Right side: Order Info and Supplier/Customer Info
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Order Info",
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      _buildInfoRow(
                                          "Order ID", _localOrder.orderId),
                                      _buildInfoRow("Delivery Date",
                                          _localOrder.orderDate.split(' ')[0]),
                                      _buildInfoRow(
                                          "Order Time",
                                          _localOrder.orderDate
                                                      .split(' ')
                                                      .length >
                                                  1
                                              ? _localOrder.orderDate
                                                  .split(' ')[1]
                                              : "N/A"),
                                      SizedBox(height: 6.h),
                                      _buildInfoRow(
                                          "Payment Status", _localOrder.status),
                                      Divider(
                                          color: Colors.white24, height: 20.h),
                                      Row(
                                        children: [
                                          Text(
                                            "Status:",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          _buildStatusPill(_localOrder.status),
                                        ],
                                      ),

                                      // Show customer order action buttons for pending orders
                                      if (!widget.isSupplierMode &&
                                          _localOrder.status == "Pending") ...[
                                        SizedBox(height: 20.h),
                                        Text(
                                          "Order Actions:",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        // Add note field for actions
                                        // Update the note field UI label to be clear
                                        TextField(
                                          controller: _noteController,
                                          maxLines: 3,
                                          style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Add a note for this order (optional)...',
                                            hintStyle: GoogleFonts.spaceGrotesk(
                                                color: Colors.white38),
                                            filled: true,
                                            fillColor:
                                                Colors.white.withOpacity(0.05),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.all(12.w),
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 0, 224, 116),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.r),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12.h),
                                                ),
                                                onPressed: _acceptCustomerOrder,
                                                child: Text(
                                                  "Accept Order",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 229, 62, 62),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.r),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12.h),
                                                ),
                                                onPressed: _rejectCustomerOrder,
                                                child: Text(
                                                  "Reject Order",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Show note if available
                                      if (_localOrder.note != null &&
                                          _localOrder.note!.isNotEmpty) ...[
                                        SizedBox(height: 16.h),
                                        Text(
                                          "Note:",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Container(
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                          child: Text(
                                            _localOrder.note!,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 14.sp,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],

                                      SizedBox(height: 20.h),
                                      Text(
                                        // Change text based on mode
                                        widget.isSupplierMode
                                            ? "Supplier info"
                                            : "Customer info",
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      _buildInfoRow(
                                          "Name", _localOrder.storeName),
                                      _buildInfoRow(
                                          "Phone", _localOrder.phoneNo),
                                      _buildInfoRow(
                                          "Email",
                                          widget.isSupplierMode
                                              ? (_orderDetails != null &&
                                                      _orderDetails![
                                                              'supplier'] !=
                                                          null &&
                                                      _orderDetails!['supplier']
                                                              ['user'] !=
                                                          null
                                                  ? _orderDetails!['supplier']
                                                      ['user']['email']
                                                  : "N/A")
                                              : (_orderDetails != null &&
                                                      _orderDetails![
                                                              'customer'] !=
                                                          null &&
                                                      _orderDetails!['customer']
                                                              ['user'] !=
                                                          null
                                                  ? _orderDetails!['customer']
                                                      ['user']['email']
                                                  : "N/A")),
                                      _buildInfoRow(
                                          "Address",
                                          widget.isSupplierMode
                                              ? "N/A"
                                              : (_orderDetails != null &&
                                                      _orderDetails![
                                                              'customer'] !=
                                                          null &&
                                                      _orderDetails!['customer']
                                                              ['address'] !=
                                                          null
                                                  ? _orderDetails!['customer']
                                                      ['address']
                                                  : "N/A")),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color textColor;
    Color borderColor;

    // Use the same color scheme as in the OrderTable
    switch (status) {
      case "Accepted":
        textColor = const Color.fromARGB(255, 0, 196, 255); // cyan
        borderColor = textColor;
        break;
      case "Pending":
        textColor = const Color.fromARGB(255, 255, 232, 29); // yellow
        borderColor = textColor;
        break;
      case "Delivered":
      case "Shipped":
        textColor = const Color.fromARGB(178, 0, 224, 116); // green
        borderColor = textColor;
        break;
      case "Declined":
      case "Rejected":
        textColor = const Color.fromARGB(255, 229, 62, 62); // red
        borderColor = textColor;
        break;
      case "Prepared":
        textColor = const Color.fromARGB(255, 255, 150, 30); // orange
        borderColor = textColor;
        break;
      case "on_theway":
        textColor = const Color.fromARGB(255, 130, 80, 223); // purple
        borderColor = textColor;
        break;
      default:
        textColor = Colors.white70;
        borderColor = Colors.white54;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
