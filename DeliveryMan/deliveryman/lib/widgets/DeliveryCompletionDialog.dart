import 'dart:convert';
import 'dart:typed_data';
import 'package:deliveryman/widgets/SignatureCaptureWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../widgets/custom_button.dart';

enum PaymentMethod { cash, partial, debt }

class DeliveryCompletionDialog extends StatefulWidget {
  final Order order;
  final Function(Map<String, dynamic>) onComplete;
  final VoidCallback onCancel;

  const DeliveryCompletionDialog({
    Key? key,
    required this.order,
    required this.onComplete,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<DeliveryCompletionDialog> createState() =>
      _DeliveryCompletionDialogState();
}

class _DeliveryCompletionDialogState extends State<DeliveryCompletionDialog> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Uint8List? _signatureBytes;

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.order.totalCost.toStringAsFixed(2);
    _notesController.text = 'Customer paid and signed';
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPaymentMethodChanged(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;

      switch (method) {
        case PaymentMethod.cash:
          _amountPaidController.text =
              widget.order.totalCost.toStringAsFixed(2);
          _notesController.text = 'Customer paid cash and signed';
          break;
        case PaymentMethod.partial:
          _amountPaidController.text = '0.00';
          _notesController.text =
              'Customer paid partial amount, balance added to account';
          break;
        case PaymentMethod.debt:
          _amountPaidController.text = '0.00';
          _notesController.text = 'Regular customer - added to account, signed';
          break;
      }
    });
  }

  void _showSignatureCapture() {
    // Use the fixed signature capture dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SignatureCaptureWidget(
          onSignatureConfirmed: (signatureBytes) {
            setState(() {
              _signatureBytes = signatureBytes;
            });
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  bool _validateForm() {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    final totalAmount = widget.order.totalCost;

    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        if (amountPaid != totalAmount) {
          _showError(
              'For cash payment, amount paid must equal total amount (\$${totalAmount.toStringAsFixed(2)})');
          return false;
        }
        break;
      case PaymentMethod.partial:
        if (amountPaid <= 0 || amountPaid >= totalAmount) {
          _showError(
              'For partial payment, amount must be greater than 0 and less than total amount');
          return false;
        }
        break;
      case PaymentMethod.debt:
        if (amountPaid != 0) {
          _showError('For debt payment, amount paid must be 0');
          return false;
        }
        break;
    }

    if (_signatureBytes == null) {
      _showError('Customer signature is required');
      return false;
    }

    if (_notesController.text.trim().isEmpty) {
      _showError('Delivery notes are required');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _completeDelivery() {
    if (!_validateForm()) return;

    try {
      final amountPaid = double.parse(_amountPaidController.text);
      final paymentMethodString =
          _selectedPaymentMethod.toString().split('.').last;

      final signatureBase64 = base64Encode(_signatureBytes!);

      final deliveryData = {
        'orderId': widget.order.id.toString(),
        'paymentMethod': paymentMethodString,
        'totalAmount': widget.order.totalCost.toStringAsFixed(2),
        'amountPaid': amountPaid.toStringAsFixed(2),
        'deliveryNotes': _notesController.text.trim(),
        'signatureImage': signatureBase64,
      };

      // Call the completion callback immediately - parent handles loading
      widget.onComplete(deliveryData);
    } catch (e) {
      _showError('Error processing delivery completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: double.infinity, // Take full width
          height: double.infinity, // Take full height
          color: Colors.black54, // Semi-transparent background
          child: Center(
            child: Container(
              // Use fixed margins instead of percentage to ensure full width usage
              margin:
                  const EdgeInsets.all(12), // Small margin from screen edges
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                minWidth: MediaQuery.of(context).size.width -
                    24, // Full width minus margins
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF304050),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6941C6).withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6941C6),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete Delivery',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Order #${widget.order.id} - ${widget.order.customerName}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _signatureBytes != null
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: _signatureBytes != null
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _signatureBytes != null ? 'Ready' : 'Pending',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Summary - Full width
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2939),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6941C6).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Color(0xFF6941C6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order Summary',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Customer:',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              color: const Color(0xAAFFFFFF),
                                            ),
                                          ),
                                          Text(
                                            widget.order.customerName,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Total Amount:',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            color: const Color(0xAAFFFFFF),
                                          ),
                                        ),
                                        Text(
                                          '\$${widget.order.totalCost.toStringAsFixed(2)}',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag,
                                      color: Color(0xFF6941C6),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.order.items.length} items • Order #${widget.order.id}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        color: const Color(0xAAFFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Payment Method Selection - Full width
                          Text(
                            'Payment Method',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Payment method cards - Use full width
                          Column(
                            children: PaymentMethod.values.map((method) {
                              final isSelected =
                                  _selectedPaymentMethod == method;
                              String title;
                              String subtitle;
                              IconData icon;
                              Color color;

                              switch (method) {
                                case PaymentMethod.cash:
                                  title = 'Cash Payment';
                                  subtitle =
                                      'Customer pays full amount in cash';
                                  icon = Icons.attach_money;
                                  color = const Color(0xFF4CAF50);
                                  break;
                                case PaymentMethod.partial:
                                  title = 'Partial Payment';
                                  subtitle =
                                      'Customer pays part, rest added to account';
                                  icon = Icons.payment;
                                  color = const Color(0xFFFF9800);
                                  break;
                                case PaymentMethod.debt:
                                  title = 'Add to Account';
                                  subtitle =
                                      'Full amount added to customer account';
                                  icon = Icons.account_balance;
                                  color = const Color(0xFF2196F3);
                                  break;
                              }

                              return Container(
                                width: double.infinity, // Full width
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _onPaymentMethodChanged(method),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.1)
                                          : const Color(0xFF1D2939),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : const Color(0xFF6941C6)
                                                .withOpacity(0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: color,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14,
                                                  color:
                                                      const Color(0xAAFFFFFF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Radio<PaymentMethod>(
                                          value: method,
                                          groupValue: _selectedPaymentMethod,
                                          onChanged: (value) =>
                                              _onPaymentMethodChanged(value!),
                                          activeColor: color,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Amount and Notes - Full width row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amount Paid Input
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount Paid',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _amountPaidController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter amount paid',
                                      prefixText: '\$ ',
                                      prefixStyle: GoogleFonts.spaceGrotesk(
                                        color: const Color(0xFF4CAF50),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1D2939),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF424A56)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF6941C6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Delivery Notes
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Notes',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Enter delivery notes',
                                      filled: true,
                                      fillColor: const Color(0xFF1D2939),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF424A56)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF6941C6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Signature Section - Full width
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2939),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _signatureBytes != null
                                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                                    : const Color(0xFF6941C6).withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _signatureBytes != null
                                          ? Icons.check_circle
                                          : Icons.edit,
                                      color: _signatureBytes != null
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFF6941C6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Customer Signature',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if (_signatureBytes != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF4CAF50),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Signature Captured',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 12,
                                                color: const Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity, // Full width button
                                  child: CustomButton(
                                    text: _signatureBytes == null
                                        ? 'Enter Signature'
                                        : 'Update Signature',
                                    onPressed: _showSignatureCapture,
                                    backgroundColor: _signatureBytes == null
                                        ? const Color(0xFF6941C6)
                                        : const Color(0xFF1D2939),
                                    icon: Icon(
                                      _signatureBytes == null
                                          ? Icons.edit
                                          : Icons.refresh,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons - Full width - FIXED VERSION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: widget.onCancel,
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          // ✅ Fixed: Changed from SizedBox to Expanded
                          flex: 2, // Give the Complete button more space
                          child: CustomButton(
                            text: 'Complete',
                            onPressed: _completeDelivery,
                            isLoading: false,
                            backgroundColor: const Color(0xFF4CAF50),
                            icon: const Icon(Icons.check_circle, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Updated method to show the dialog with full width
void showDeliveryCompletionDialog(BuildContext context, Order order,
    Function(Map<String, dynamic>) onComplete, VoidCallback onCancel) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent, // No additional background
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return DeliveryCompletionDialog(
        order: order,
        onComplete: onComplete,
        onCancel: onCancel,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}
