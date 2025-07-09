// lib/supplier/widgets/orderwidgets/OrderDetailsWidget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';
import 'package:storify/supplier/widgets/orderwidgets/apiService.dart';
import 'package:storify/utilis/notification_service.dart';

class OrderDetailsWidget extends StatefulWidget {
  final Order orderDetails;
  final VoidCallback onClose;
  final VoidCallback onStatusUpdate;
  final ApiService apiService;

  const OrderDetailsWidget({
    Key? key,
    required this.orderDetails,
    required this.onClose,
    required this.onStatusUpdate,
    required this.apiService,
  }) : super(key: key);

  @override
  State<OrderDetailsWidget> createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  // Keep track of selected products for decline
  final Map<int, bool> _selectedProducts = {};
  // Keep track of edited prices
  final Map<int, double> _editedPrices = {};
  // Keep track of product dates and notes
  final Map<int, DateTime> _productionDates = {};
  final Map<int, DateTime> _expiryDates = {};
  final Map<int, String> _productNotes = {};

  // Track if any price was edited
  bool get _hasPriceEdits => _editedPrices.isNotEmpty;
  bool get _hasSelectedProducts => _selectedProducts.values.contains(true);
  bool get _hasDateEdits =>
      _productionDates.isNotEmpty || _expiryDates.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Initialize all products as unselected (will be accepted)
    for (var product in widget.orderDetails.products) {
      _selectedProducts[product.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: EdgeInsets.only(top: 20.h),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color.fromARGB(255, 34, 53, 62),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            _buildHeader(),

            // Order info sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _buildOrderInfo(),
                  SizedBox(height: 24.h),
                  _buildProductsList(),
                  SizedBox(height: 24.h),
                  _buildPricingSummary(),
                  SizedBox(height: 16.h),
                  if (widget.orderDetails.note != null) _buildNotes(),
                  SizedBox(height: 24.h),
                  _buildActionButtons(context),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.orderDetails,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: Colors.white70,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.orderInformation,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                      l10n.orderIdLabel, widget.orderDetails.orderId),
                  SizedBox(height: 12.h),
                  _buildInfoItem(l10n.dateLabel, widget.orderDetails.orderDate),
                  SizedBox(height: 12.h),
                  _buildInfoItem(l10n.statusLabel, widget.orderDetails.status,
                      isStatus: true),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  if (widget.orderDetails.paymentMethod != null)
                    _buildInfoItem(
                        l10n.paymentLabel, widget.orderDetails.paymentMethod!),
                ],
              ),
            ),
          ],
        ),
        if (widget.orderDetails.deliveryAddress != null) ...[
          SizedBox(height: 12.h),
          _buildInfoItem(
              l10n.deliveryAddressLabel, widget.orderDetails.deliveryAddress!),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isStatus = false}) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
        ),
        SizedBox(height: 4.h),
        if (isStatus)
          _buildStatusPill(value)
        else
          Text(
            value,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
          ),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    // Get localized status text
    String displayStatus;
    switch (status) {
      case "Accepted":
        displayStatus = l10n.acceptedStatus;
        break;
      case "Pending":
        displayStatus = l10n.pendingStatus;
        break;
      case "Delivered":
        displayStatus = l10n.deliveredStatus;
        break;
      case "Declined":
        displayStatus = l10n.declinedStatus;
        break;
      case "PartiallyAccepted":
        displayStatus = l10n.partiallyAcceptedStatus;
        break;
      default:
        displayStatus = status;
    }

    Color textColor;
    Color borderColor;
    if (status == "Accepted") {
      textColor = const Color.fromARGB(255, 0, 196, 255); // cyan
      borderColor = textColor;
    } else if (status == "Pending") {
      textColor = const Color.fromARGB(255, 255, 232, 29); // yellow
      borderColor = textColor;
    } else if (status == "Delivered") {
      textColor = const Color.fromARGB(178, 0, 224, 116); // green
      borderColor = textColor;
    } else if (status == "Declined") {
      textColor = const Color.fromARGB(255, 229, 62, 62); // red
      borderColor = textColor;
    } else if (status == "PartiallyAccepted") {
      textColor = const Color.fromARGB(255, 255, 136, 0); // orange
      borderColor = textColor;
    } else {
      textColor = Colors.white70;
      borderColor = Colors.white54;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        displayStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
      ),
    );
  }

  Widget _buildProductsList() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    bool showSelectionControls = widget.orderDetails.status == "Pending";
    bool canEditPrices = widget.orderDetails.status == "Pending";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.productsLabel,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            if (showSelectionControls)
              Row(
                children: [
                  if (canEditPrices)
                    Padding(
                      padding: EdgeInsets.only(
                        left: isRtl ? 16.w : 0,
                        right: isRtl ? 0 : 16.w,
                      ),
                      child: Text(
                        l10n.tapToEditDetails,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                      ),
                    ),
                  Text(
                    l10n.selectProductsToDecline,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 29, 41, 57),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color.fromARGB(255, 34, 53, 62),
              width: 1,
            ),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.orderDetails.products.length,
            separatorBuilder: (context, index) => Divider(
              color: const Color.fromARGB(255, 34, 53, 62),
              height: 1.h,
            ),
            itemBuilder: (context, index) {
              final product = widget.orderDetails.products[index];
              final bool isSelected = _selectedProducts[product.id] ?? false;

              // Get current price (either edited or original)
              final double currentPrice =
                  _editedPrices[product.id] ?? product.price;
              final double currentTotalPrice = currentPrice * product.quantity;

              // Show product status if order is PartiallyAccepted
              final bool showProductStatus =
                  widget.orderDetails.status == "PartiallyAccepted" &&
                      product.status != null;

              // Check if this product has custom data (from API or local editing)
              final bool hasCustomData =
                  _productionDates.containsKey(product.id) ||
                      _expiryDates.containsKey(product.id) ||
                      _productNotes.containsKey(product.id) ||
                      _editedPrices.containsKey(product.id) ||
                      product.hasCustomData; // Also check data from API

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Checkbox for selection (only shown for pending orders)
                        if (showSelectionControls)
                          Padding(
                            padding: EdgeInsets.only(
                              left: isRtl ? 8.w : 0,
                              right: isRtl ? 0 : 8.w,
                            ),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedProducts[product.id] =
                                      value ?? false;
                                });
                              },
                              activeColor:
                                  const Color.fromARGB(255, 229, 62, 62),
                              checkColor: Colors.white,
                              side: BorderSide(color: Colors.white54),
                            ),
                          ),

                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 36, 50, 69),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: product.imageUrl != null
                                ? Image.network(
                                    product.imageUrl!,
                                    width: 40.w,
                                    height: 40.h,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white70,
                                    size: 24.sp,
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text(
                                    "${l10n.idPrefix}${product.productId}",
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            fontSize: 14.sp,
                                            color: Colors.white70,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            fontSize: 14.sp,
                                            color: Colors.white70,
                                          ),
                                  ),
                                  if (showProductStatus) ...[
                                    SizedBox(width: 8.w),
                                    _buildProductStatusPill(product.status!),
                                  ],
                                  if (hasCustomData) ...[
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.edit,
                                      size: 14.sp,
                                      color: const Color.fromARGB(
                                          255, 105, 65, 198),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Total price display
                            Text(
                              "\$${currentTotalPrice.toStringAsFixed(2)}",
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                            ),
                            SizedBox(height: 4.h),
                            // Price per unit
                            Text(
                              "${product.quantity} × \$${currentPrice.toStringAsFixed(2)}",
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 14.sp,
                                      color:
                                          _editedPrices.containsKey(product.id)
                                              ? const Color.fromARGB(
                                                  255, 105, 65, 198)
                                              : Colors.white70,
                                      fontWeight:
                                          _editedPrices.containsKey(product.id)
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 14.sp,
                                      color:
                                          _editedPrices.containsKey(product.id)
                                              ? const Color.fromARGB(
                                                  255, 105, 65, 198)
                                              : Colors.white70,
                                      fontWeight:
                                          _editedPrices.containsKey(product.id)
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                            ),
                          ],
                        ),
                        // Edit button for pending orders
                        if (canEditPrices)
                          Padding(
                            padding: EdgeInsets.only(
                              left: isRtl ? 0 : 8.w,
                              right: isRtl ? 8.w : 0,
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  _showProductEditDialog(context, product),
                              icon: Icon(
                                Icons.edit,
                                color: hasCustomData
                                    ? const Color.fromARGB(255, 105, 65, 198)
                                    : Colors.white54,
                                size: 20.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Show custom dates and notes if available (for all order statuses)
                    if (hasCustomData)
                      Padding(
                        padding: EdgeInsets.only(
                            top: 8.h,
                            left: showSelectionControls
                                ? (isRtl ? 0 : 40.w)
                                : 0.w,
                            right: showSelectionControls
                                ? (isRtl ? 40.w : 0)
                                : 0.w),
                        child: _buildProductCustomInfo(product),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCustomInfo(OrderProduct product) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    List<Widget> infoChips = [];

    // Check for production date (local editing takes priority over API data)
    DateTime? displayProdDate;
    if (_productionDates.containsKey(product.id)) {
      displayProdDate = _productionDates[product.id];
    } else if (product.productionDateTime != null) {
      displayProdDate = product.productionDateTime;
    }

    if (displayProdDate != null) {
      infoChips.add(_buildInfoChip(
        "${l10n.prodDatePrefix}${displayProdDate.day}/${displayProdDate.month}/${displayProdDate.year}",
        Colors.blue,
        icon: Icons.production_quantity_limits,
      ));
    }

    // Check for expiry date (local editing takes priority over API data)
    DateTime? displayExpDate;
    if (_expiryDates.containsKey(product.id)) {
      displayExpDate = _expiryDates[product.id];
    } else if (product.expiryDateTime != null) {
      displayExpDate = product.expiryDateTime;
    }

    if (displayExpDate != null) {
      infoChips.add(_buildInfoChip(
        "${l10n.expDatePrefix}${displayExpDate.day}/${displayExpDate.month}/${displayExpDate.year}",
        Colors.orange,
        icon: Icons.schedule,
      ));
    }

    // Check for notes (local editing takes priority over API data)
    String? displayNotes;
    if (_productNotes.containsKey(product.id) &&
        _productNotes[product.id]!.isNotEmpty) {
      displayNotes = _productNotes[product.id];
    } else if (product.notes != null && product.notes!.isNotEmpty) {
      displayNotes = product.notes;
    }

    if (displayNotes != null) {
      infoChips.add(_buildInfoChip(
        displayNotes,
        Colors.purple,
        icon: Icons.note,
      ));
    }

    // Show price modification indicator if price was edited
    if (_editedPrices.containsKey(product.id)) {
      infoChips.add(_buildInfoChip(
        l10n.priceModified,
        const Color.fromARGB(255, 105, 65, 198),
        icon: Icons.attach_money,
      ));
    }

    return SizedBox(
      width: double.infinity, // Add this to take full width
      child: Wrap(
        alignment: WrapAlignment.start, // Add this to align to start
        spacing: 8.w,
        runSpacing: 4.h,
        children: infoChips,
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color, {IconData? icon}) {
    final isArabic = LocalizationHelper.isArabic(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12.sp,
              color: color,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            text,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
          ),
        ],
      ),
    );
  }

  // Method to show product edit dialog (combines price, dates, and notes)
  void _showProductEditDialog(BuildContext context, OrderProduct product) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Current values (either edited, from API, or default)
    final double currentPrice = _editedPrices[product.id] ?? product.price;

    // For dates, use local editing state, then API data, then default
    final DateTime currentProdDate = _productionDates[product.id] ??
        product.productionDateTime ??
        DateTime.now();
    final DateTime currentExpDate = _expiryDates[product.id] ??
        product.expiryDateTime ??
        DateTime.now().add(Duration(days: 30));

    // For notes, use local editing state, then API data, then empty
    final String currentNotes =
        _productNotes[product.id] ?? product.notes ?? "";

    // Controllers
    final TextEditingController priceController = TextEditingController(
      text: currentPrice.toStringAsFixed(2),
    );
    final TextEditingController notesController = TextEditingController(
      text: currentNotes,
    );

    // State variables for the dialog
    DateTime selectedProdDate = currentProdDate;
    DateTime selectedExpDate = currentExpDate;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 36, 50, 69),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              l10n.editProductDetails,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
            ),
            content: Container(
              width: 400.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${l10n.productPrefix}${product.name}",
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
                    SizedBox(height: 16.h),

                    // Price section
                    Text(
                      l10n.pricePerUnit,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 29, 41, 57),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color.fromARGB(255, 34, 53, 62),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: priceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        style: isArabic
                            ? GoogleFonts.cairo(color: Colors.white)
                            : GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: isArabic
                              ? GoogleFonts.cairo(color: Colors.white70)
                              : GoogleFonts.spaceGrotesk(color: Colors.white70),
                          hintText: "0.00",
                          hintStyle: isArabic
                              ? GoogleFonts.cairo(color: Colors.white30)
                              : GoogleFonts.spaceGrotesk(color: Colors.white30),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Production Date section
                    Text(
                      l10n.productionDate,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedProdDate,
                          firstDate:
                              DateTime.now().subtract(Duration(days: 365)),
                          lastDate: DateTime.now().add(Duration(days: 30)),
                          builder: (context, child) {
                            return Directionality(
                              textDirection:
                                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary:
                                        const Color.fromARGB(255, 105, 65, 198),
                                    surface:
                                        const Color.fromARGB(255, 36, 50, 69),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedProdDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 29, 41, 57),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color.fromARGB(255, 34, 53, 62),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${selectedProdDate.day}/${selectedProdDate.month}/${selectedProdDate.year}",
                              style: isArabic
                                  ? GoogleFonts.cairo(color: Colors.white)
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                            ),
                            Icon(Icons.calendar_today,
                                color: Colors.white70, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Expiry Date section
                    Text(
                      l10n.expiryDate,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedExpDate,
                          firstDate: selectedProdDate,
                          lastDate: DateTime.now()
                              .add(Duration(days: 1095)), // 3 years
                          builder: (context, child) {
                            return Directionality(
                              textDirection:
                                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary:
                                        const Color.fromARGB(255, 105, 65, 198),
                                    surface:
                                        const Color.fromARGB(255, 36, 50, 69),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedExpDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 29, 41, 57),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color.fromARGB(255, 34, 53, 62),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${selectedExpDate.day}/${selectedExpDate.month}/${selectedExpDate.year}",
                              style: isArabic
                                  ? GoogleFonts.cairo(color: Colors.white)
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                            ),
                            Icon(Icons.calendar_today,
                                color: Colors.white70, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Notes section
                    Text(
                      l10n.notesOptional,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 29, 41, 57),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color.fromARGB(255, 34, 53, 62),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: notesController,
                        maxLines: 3,
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        style: isArabic
                            ? GoogleFonts.cairo(color: Colors.white)
                            : GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: l10n.notesHint,
                          hintStyle: isArabic
                              ? GoogleFonts.cairo(color: Colors.white30)
                              : GoogleFonts.spaceGrotesk(color: Colors.white30),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Calculate new total
                    StatefulBuilder(
                      builder: (context, setState) {
                        double newPrice = 0.0;
                        try {
                          newPrice = double.parse(priceController.text);
                        } catch (e) {
                          newPrice = 0.0;
                        }
                        final double newTotal = newPrice * product.quantity;

                        return Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 29, 41, 57),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color.fromARGB(255, 34, 53, 62),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.newTotal,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                              ),
                              Text(
                                "\$${newTotal.toStringAsFixed(2)}",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 105, 65, 198),
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 105, 65, 198),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Reset button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Remove local editing data (this will revert to API data if available)
                    _editedPrices.remove(product.id);
                    _productionDates.remove(product.id);
                    _expiryDates.remove(product.id);
                    _productNotes.remove(product.id);
                  });
                },
                child: Text(
                  "${l10n.resetTo} ${product.hasCustomData ? l10n.originalData : l10n.defaultData}",
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancelButton,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                onPressed: () {
                  try {
                    final double newPrice = double.parse(priceController.text);
                    if (newPrice <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.priceValidationError),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() {
                      // Update price only if different from original
                      if (newPrice != product.price) {
                        _editedPrices[product.id] = newPrice;
                      } else {
                        _editedPrices.remove(product.id);
                      }

                      // Update dates
                      _productionDates[product.id] = selectedProdDate;
                      _expiryDates[product.id] = selectedExpDate;

                      // Update notes
                      if (notesController.text.trim().isNotEmpty) {
                        _productNotes[product.id] = notesController.text.trim();
                      } else {
                        _productNotes.remove(product.id);
                      }
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.validPriceError),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  l10n.updateDetails,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )
                      : GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductStatusPill(String status) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    // Get localized status text
    String displayStatus;
    switch (status) {
      case "Accepted":
        displayStatus = l10n.acceptedStatus;
        break;
      case "Declined":
        displayStatus = l10n.declinedStatus;
        break;
      default:
        displayStatus = status;
    }

    Color color;

    if (status == "Accepted") {
      color = const Color.fromARGB(178, 0, 224, 116); // green
    } else if (status == "Declined") {
      color = const Color.fromARGB(255, 229, 62, 62); // red
    } else {
      color = Colors.white70;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color),
      ),
      child: Text(
        displayStatus,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
      ),
    );
  }

  Widget _buildPricingSummary() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Calculate the new total if there are price edits
    double calculatedTotal = 0.0;

    if (_hasPriceEdits) {
      for (var product in widget.orderDetails.products) {
        // Get current price (either edited or original)
        final double currentPrice = _editedPrices[product.id] ?? product.price;
        calculatedTotal += currentPrice * product.quantity;
      }
    } else {
      calculatedTotal = widget.orderDetails.totalAmount;
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color.fromARGB(255, 34, 53, 62),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            l10n.totalLabel,
            "\$${calculatedTotal.toStringAsFixed(2)}",
            isTotal: true,
            isEdited: _hasPriceEdits,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isTotal = false, bool isEdited = false}) {
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: isTotal ? 16.sp : 14.sp,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? Colors.white : Colors.white70,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: isTotal ? 16.sp : 14.sp,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: isTotal ? Colors.white : Colors.white70,
                ),
        ),
        Row(
          children: [
            if (isEdited)
              Padding(
                padding: EdgeInsets.only(
                  left: isRtl ? 6.w : 0,
                  right: isRtl ? 0 : 6.w,
                ),
                child: Icon(
                  Icons.edit,
                  size: 14.sp,
                  color: const Color.fromARGB(255, 105, 65, 198),
                ),
              ),
            Text(
              amount,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: isTotal ? 18.sp : 14.sp,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                      color: isTotal
                          ? const Color.fromARGB(255, 105, 65, 198)
                          : Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: isTotal ? 18.sp : 14.sp,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                      color: isTotal
                          ? const Color.fromARGB(255, 105, 65, 198)
                          : Colors.white,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotes() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notesLabel,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 29, 41, 57),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color.fromARGB(255, 34, 53, 62),
              width: 1,
            ),
          ),
          child: Text(
            widget.orderDetails.note!,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Actions depend on the current status
    List<Widget> actions = [];

    if (widget.orderDetails.status == "Pending") {
      if (_hasSelectedProducts) {
        // When products are selected for decline, show Accept Partially button
        actions = [
          Expanded(
            child: _buildActionButton(
              l10n.acceptPartially +
                  (_hasPriceEdits || _hasDateEdits
                      ? " ${l10n.withChanges}"
                      : ""),
              const Color.fromARGB(255, 255, 136, 0), // orange
              () => _showPartialAcceptanceDialog(context),
              isPrimary: true,
            ),
          ),
        ];
      } else {
        // For pending orders without selection, allow accept or decline
        actions = [
          Expanded(
            child: _buildActionButton(
              l10n.declineButton,
              const Color.fromARGB(255, 229, 62, 62),
              () => _showDeclineDialog(context),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildActionButton(
              l10n.acceptButton +
                  (_hasPriceEdits || _hasDateEdits
                      ? " ${l10n.withChanges}"
                      : ""),
              const Color.fromARGB(255, 105, 65, 198),
              () => _updateOrderStatus(context, "Accepted"),
              isPrimary: true,
            ),
          ),
        ];
      }
    } else {
      // For other statuses, just show a debugprint invoice button
      actions = [
        Expanded(
          child: _buildActionButton(
            l10n.printInvoice,
            const Color.fromARGB(255, 105, 65, 198),
            () {},
            isPrimary: true,
          ),
        ),
      ];
    }

    return Row(children: actions);
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    final isArabic = LocalizationHelper.isArabic(context);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.transparent,
        foregroundColor: isPrimary ? Colors.white : color,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        elevation: isPrimary ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: color,
            width: 1.5,
          ),
        ),
      ),
      child: Text(
        text,
        style: isArabic
            ? GoogleFonts.cairo(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              )
            : GoogleFonts.spaceGrotesk(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }

  // Show dialog for partial acceptance
  void _showPartialAcceptanceDialog(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    String note = '';
    final int declinedCount =
        _selectedProducts.values.where((selected) => selected).length;
    final int totalProducts = widget.orderDetails.products.length;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            l10n.partiallyAcceptOrder,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partialAcceptanceDescription,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.productsWillBeDeclined(declinedCount, totalProducts),
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
              ),
              if (_hasPriceEdits) ...[
                SizedBox(height: 8.h),
                Text(
                  l10n.pricesModified(_editedPrices.length),
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                ),
              ],
              if (_hasDateEdits) ...[
                SizedBox(height: 8.h),
                Text(
                  l10n.datesHaveBeenSet,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 105, 65, 198),
                        ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                l10n.providePartialReason,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 29, 41, 57),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color.fromARGB(255, 34, 53, 62),
                    width: 1,
                  ),
                ),
                child: TextField(
                  maxLines: 3,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.partialReasonHint,
                    hintStyle: isArabic
                        ? GoogleFonts.cairo(color: Colors.white30)
                        : GoogleFonts.spaceGrotesk(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12.r),
                  ),
                  onChanged: (value) {
                    note = value;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancelButton,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 255, 136, 0), // orange
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () {
                if (note.trim().isEmpty) {
                  // Show validation error if note is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.partialReasonRequired),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _acceptPartially(context, note);
              },
              child: Text(
                l10n.confirmButton,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to accept order partially
  void _acceptPartially(BuildContext context, String note) {
    // Create list of declined items and all updates
    List<Map<String, dynamic>> updatedItems = [];
    int declinedCount = 0;

    // Process each product
    for (var product in widget.orderDetails.products) {
      final bool isDeclined = _selectedProducts[product.id] ?? false;

      Map<String, dynamic> itemData = {
        "id": product.productId, // Use productId instead of item ID
      };

      if (isDeclined) {
        declinedCount++;
        itemData["status"] = "Declined";
      } else {
        itemData["status"] = "Accepted";

        // Add price if edited
        if (_editedPrices.containsKey(product.id)) {
          itemData["costPrice"] = _editedPrices[product.id];
        }
      }

      // Add dates if set (for both accepted and declined items)
      if (_productionDates.containsKey(product.id)) {
        final prodDate = _productionDates[product.id]!;
        itemData["prodDate"] =
            "${prodDate.year}-${prodDate.month.toString().padLeft(2, '0')}-${prodDate.day.toString().padLeft(2, '0')}";
      }

      if (_expiryDates.containsKey(product.id)) {
        final expDate = _expiryDates[product.id]!;
        itemData["expDate"] =
            "${expDate.year}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}";
      }

      // Add notes if set
      if (_productNotes.containsKey(product.id) &&
          _productNotes[product.id]!.isNotEmpty) {
        itemData["notes"] = _productNotes[product.id];
      }

      updatedItems.add(itemData);
    }

    // If all products are declined, change overall status to "Declined"
    final String orderStatus =
        (declinedCount >= widget.orderDetails.products.length)
            ? "Declined"
            : "Accepted"; // Backend will set to PartiallyAccepted

    // Call update method with partial acceptance details
    _updateOrderStatus(
      context,
      orderStatus,
      note: note,
      declinedItems: updatedItems,
    );
  }

  // Method to update order status
  Future<void> _updateOrderStatus(
    BuildContext context,
    String status, {
    String? note,
    List<Map<String, dynamic>>? declinedItems,
  }) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    BuildContext? dialogContext;

    try {
      debugPrint('Starting order status update: $status');
      debugPrint('Note: $note');

      // If accepting the entire order with changes, create items array
      if (status == "Accepted" &&
          (_hasPriceEdits || _hasDateEdits || _productNotes.isNotEmpty) &&
          (declinedItems == null || declinedItems.isEmpty)) {
        declinedItems = [];

        for (var product in widget.orderDetails.products) {
          Map<String, dynamic> itemData = {
            "id": product.productId,
            "status": "Accepted",
          };

          // Add price if edited
          if (_editedPrices.containsKey(product.id)) {
            itemData["costPrice"] = _editedPrices[product.id];
          }

          // Add dates if set
          if (_productionDates.containsKey(product.id)) {
            final prodDate = _productionDates[product.id]!;
            itemData["prodDate"] =
                "${prodDate.year}-${prodDate.month.toString().padLeft(2, '0')}-${prodDate.day.toString().padLeft(2, '0')}";
          }

          if (_expiryDates.containsKey(product.id)) {
            final expDate = _expiryDates[product.id]!;
            itemData["expDate"] =
                "${expDate.year}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}";
          }

          // Add notes if set
          if (_productNotes.containsKey(product.id) &&
              _productNotes[product.id]!.isNotEmpty) {
            itemData["notes"] = _productNotes[product.id];
          }

          declinedItems.add(itemData);
        }
      }

      debugPrint('Updated items: $declinedItems');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Call API
      final success = await widget.apiService.updateOrderStatus(
        widget.orderDetails.id,
        status,
        note: note,
        declinedItems: declinedItems,
      );

      debugPrint('API call completed, success: $success');

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      if (success) {
        // Send notification to admin
        await _sendStatusUpdateNotification(status, note,
            isPartial: declinedItems != null &&
                declinedItems.isNotEmpty &&
                status == "Accepted" &&
                declinedItems.any((item) =>
                    item.containsKey("status") &&
                    item["status"] == "Declined"));

        // Show success message
        String statusMessage = status;
        if (status == "Accepted") {
          if (declinedItems != null &&
              declinedItems.isNotEmpty &&
              declinedItems.any((item) =>
                  item.containsKey("status") && item["status"] == "Declined")) {
            statusMessage = l10n.partiallyAcceptedMessage;
          } else if (_hasPriceEdits || _hasDateEdits) {
            statusMessage = l10n.acceptedWithChangesMessage;
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.orderStatusUpdated(
                  widget.orderDetails.orderId, statusMessage)),
              backgroundColor: Colors.green,
            ),
          );
        }

        // First call refresh to load new data
        widget.onStatusUpdate();

        // Important: Add a small delay to ensure the API has time to respond
        // before we close the details view and refresh the UI
        await Future.delayed(Duration(milliseconds: 500));

        // Then close the details panel
        widget.onClose();
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToUpdateOrderStatus),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _updateOrderStatus: $e');

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorUpdatingOrderStatus(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to send notification to admin about order status update
  Future<void> _sendStatusUpdateNotification(String status, String? note,
      {bool isPartial = false}) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    String title = '';
    String message = '';

    if (status == "Accepted") {
      if (isPartial) {
        title = l10n.orderPartiallyAcceptedNotificationTitle;
        message = l10n.orderPartiallyAcceptedNotificationMessage(
            widget.orderDetails.orderId);
      } else if (_hasPriceEdits || _hasDateEdits) {
        title = l10n.orderAcceptedWithChangesNotificationTitle;
        message = l10n.orderAcceptedWithChangesNotificationMessage(
            widget.orderDetails.orderId);
      } else {
        title = l10n.orderAcceptedNotificationTitle;
        message =
            l10n.orderAcceptedNotificationMessage(widget.orderDetails.orderId);
      }
    } else if (status == "Declined") {
      title = l10n.orderDeclinedNotificationTitle;
      message =
          l10n.orderDeclinedNotificationMessage(widget.orderDetails.orderId);
    } else if (status == "Delivered") {
      title = l10n.orderDeliveredNotificationTitle;
      message =
          l10n.orderDeliveredNotificationMessage(widget.orderDetails.orderId);
    }

    if (note != null && note.isNotEmpty) {
      message += " ${l10n.reasonPrefix}$note";
    }

    // Create additional data to include with notification
    Map<String, dynamic> additionalData = {
      'orderId': widget.orderDetails.orderId,
      'status': isPartial ? "PartiallyAccepted" : status,
      'type': 'order_status',
      'timestamp': DateTime.now().toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    };

    // Send notification to admin
    await NotificationService()
        .sendNotificationToAdmin(title, message, additionalData);
  }

  // Method to show decline dialog with note field
  void _showDeclineDialog(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    String note = '';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            l10n.declineOrderTitle,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.provideDeclineReason,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 29, 41, 57),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color.fromARGB(255, 34, 53, 62),
                    width: 1,
                  ),
                ),
                child: TextField(
                  maxLines: 4,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: isArabic
                      ? GoogleFonts.cairo(color: Colors.white)
                      : GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.enterReasonHint,
                    hintStyle: isArabic
                        ? GoogleFonts.cairo(color: Colors.white30)
                        : GoogleFonts.spaceGrotesk(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12.r),
                  ),
                  onChanged: (value) {
                    note = value;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancelButton,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 229, 62, 62),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              onPressed: () {
                if (note.trim().isEmpty) {
                  // Show validation error if note is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.declineReasonRequired),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _updateOrderStatus(context, "Declined", note: note);
              },
              child: Text(
                l10n.declineButton,
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
