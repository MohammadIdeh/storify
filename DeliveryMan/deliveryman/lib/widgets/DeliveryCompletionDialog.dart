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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default to full amount for cash payment
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

      // Update amount and notes based on payment method
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignatureCaptureWidget(
        onSignatureConfirmed: (signatureBytes) {
          setState(() {
            _signatureBytes = signatureBytes;
          });
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
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

    setState(() {
      _isProcessing = true;
    });

    try {
      final amountPaid = double.parse(_amountPaidController.text);
      final paymentMethodString =
          _selectedPaymentMethod.toString().split('.').last;

      // Convert signature to base64
      final signatureBase64 = base64Encode(_signatureBytes!);

      // Create delivery completion data
      final deliveryData = {
        'orderId': widget.order.id.toString(),
        'paymentMethod': paymentMethodString,
        'totalAmount': widget.order.totalCost.toStringAsFixed(2),
        'amountPaid': amountPaid.toStringAsFixed(2),
        'deliveryNotes': _notesController.text.trim(),
        'signatureImage': signatureBase64,
      };

      widget.onComplete(deliveryData);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error processing delivery completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF6941C6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Delivery',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Order #${widget.order.id} - ${widget.order.customerName}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          Text(
                            'Order Summary',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: const Color(0xAAFFFFFF),
                                ),
                              ),
                              Text(
                                '\$${widget.order.totalCost.toStringAsFixed(2)}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...PaymentMethod.values.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      String title;
                      String subtitle;
                      IconData icon;
                      Color color;

                      switch (method) {
                        case PaymentMethod.cash:
                          title = 'Cash Payment';
                          subtitle = 'Customer pays full amount in cash';
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
                          subtitle = 'Full amount added to customer account';
                          icon = Icons.account_balance;
                          color = const Color(0xFF2196F3);
                          break;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _onPaymentMethodChanged(method),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.1)
                                  : const Color(0xFF1D2939),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : const Color(0xFF6941C6).withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          color: const Color(0xAAFFFFFF),
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

                    const SizedBox(height: 20),

                    // Amount Paid Input
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
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter amount paid',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: const Color(0xFF1D2939),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF424A56)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6941C6)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Delivery Notes
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
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
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
                          borderSide:
                              const BorderSide(color: Color(0xFF424A56)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6941C6)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Signature Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer Signature',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_signatureBytes != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
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
                                  'Signed',
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
                    const SizedBox(height: 8),

                    CustomButton(
                      text: _signatureBytes == null
                          ? 'Capture Signature'
                          : 'Update Signature',
                      onPressed: _showSignatureCapture,
                      backgroundColor: _signatureBytes == null
                          ? const Color(0xFF6941C6)
                          : const Color(0xFF1D2939),
                      icon: Icon(
                        _signatureBytes == null ? Icons.edit : Icons.refresh,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: widget.onCancel,
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Complete Delivery',
                      onPressed: _completeDelivery,
                      isLoading: _isProcessing,
                      backgroundColor: const Color(0xFF4CAF50),
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
