// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html; // For file download on Flutter Web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/productsWidgets/product_item_Model.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

/// The ExportPopUp widget receives a list of ProductItemInformation via its constructor.
class ExportPopUp extends StatefulWidget {
  final List<ProductItemInformation> products;
  const ExportPopUp({super.key, required this.products});

  @override
  // ignore: library_private_types_in_public_api
  _ExportPopUpState createState() => _ExportPopUpState();
}

class _ExportPopUpState extends State<ExportPopUp> {
  // Dropdown state.
  String?
      _selectedAvailability; // "Active", "Not Active" (default "All" is treated as null)
  String? _selectedCategory; // Specific category; if "All", we set it to null.

  // Controllers for price fields.
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();

  // Get list of categories with "All" as the first option.
  List<String> _getCategoryList() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    List<String> categories =
        widget.products.map((p) => p.categoryName).toSet().toList();
    return [l10n.all, ...categories];
  }

  /// Determines whether the user has provided at least one filter criterion.
  bool get _hasChosenFilter {
    return (_selectedAvailability != null ||
        _selectedCategory != null ||
        _priceFromController.text.isNotEmpty ||
        _priceToController.text.isNotEmpty);
  }

  /// Filtering logic: only apply filters if a value other than "All" is chosen.
  List<ProductItemInformation> _filterProducts() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    List<ProductItemInformation> filtered = List.from(widget.products);

    // Availability filter – only applied if a valid option is chosen.
    if (_selectedAvailability != null) {
      bool avail = _selectedAvailability == l10n.active;
      filtered = filtered.where((p) => p.availability == avail).toList();
    }
    // Category filter.
    if (_selectedCategory != null) {
      filtered =
          filtered.where((p) => p.categoryName == _selectedCategory).toList();
    }

    // Price range filter.
    double priceFrom = 0;
    double priceTo = double.infinity;
    if (_priceFromController.text.isNotEmpty) {
      priceFrom = double.tryParse(_priceFromController.text) ?? 0;
    }
    if (_priceToController.text.isNotEmpty) {
      if (_priceToController.text.trim() == "∞") {
        priceTo = double.infinity;
      } else {
        priceTo = double.tryParse(_priceToController.text) ?? double.infinity;
      }
    }
    filtered = filtered
        .where((p) => p.sellPrice >= priceFrom && p.sellPrice <= priceTo)
        .toList();
    return filtered;
  }

  /// Called when the user presses Submit.
  void _onSubmit() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    // Require that the user provides at least one filter criterion.
    if (!_hasChosenFilter) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 28, 36, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.alert,
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
            l10n.pleaseChooseAtLeastOneFilterCriterion,
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
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: const BorderSide(color: Colors.white70, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
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
          ],
        ),
      );

      return;
    }

    // Get the filtered list.
    List<ProductItemInformation> filtered = _filterProducts();
    // Note: Even if the filtered list is empty (e.g. 0 to 0 range), we allow the export.
    _askForFileNameAndExport(filtered);
  }

  /// Prompts for a file name and then calls export.
  void _askForFileNameAndExport(List<ProductItemInformation> filtered) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    String fileName = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 28, 36, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.enterExcelFileName,
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
          content: TextField(
            onChanged: (value) {
              fileName = value;
            },
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: isArabic
                ? GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                  ),
            decoration: InputDecoration(
              hintText: l10n.fileNameWithoutExtension,
              hintStyle: isArabic
                  ? GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 16,
                    )
                  : GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
              filled: true,
              fillColor: const Color.fromARGB(255, 36, 50, 69),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: const BorderSide(
                    color: Color.fromARGB(255, 105, 123, 123), width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (fileName.trim().isEmpty) return;
                _exportToExcel(filtered, fileName.trim());
                Navigator.of(context).pop(); // Close file name dialog.
                Navigator.of(context).pop(); // Close export popup.
              },
              child: Text(
                l10n.export,
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
          ],
        );
      },
    );
  }

  /// Generates an Excel file using Syncfusion XLSIO and downloads it on Flutter Web.
  void _exportToExcel(List<ProductItemInformation> data, String fileName) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];

    // Column Headers with localized text.
    sheet.getRangeByName('A1').setText(l10n.idLabel);
    sheet.getRangeByName('B1').setText(l10n.productName);
    sheet.getRangeByName('C1').setText(l10n.costPrice);
    sheet.getRangeByName('D1').setText(l10n.sellPrice);
    sheet.getRangeByName('E1').setText(l10n.quantity);
    sheet.getRangeByName('F1').setText(l10n.category);
    sheet.getRangeByName('G1').setText(l10n.status);

    // Fill rows with all available data
    for (int i = 0; i < data.length; i++) {
      final rowIndex = i + 2;
      sheet
          .getRangeByName('A$rowIndex')
          .setNumber(data[i].productId.toDouble());
      sheet.getRangeByName('B$rowIndex').setText(data[i].name);
      sheet.getRangeByName('C$rowIndex').setNumber(data[i].costPrice);
      sheet.getRangeByName('D$rowIndex').setNumber(data[i].sellPrice);
      sheet.getRangeByName('E$rowIndex').setNumber(data[i].qty.toDouble());
      sheet.getRangeByName('F$rowIndex').setText(data[i].categoryName);
      sheet.getRangeByName('G$rowIndex').setText(data[i].status);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final Uint8List xlsxBytes = Uint8List.fromList(bytes);

    final html.Blob blob = html.Blob([xlsxBytes], 'application/octet-stream');
    final String url = html.Url.createObjectUrlFromBlob(blob);
    final html.AnchorElement anchor =
        html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = '$fileName.xlsx';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Get localized availability options
    final List<String> availabilityOptions = [
      l10n.all,
      l10n.active,
      l10n.notActive
    ];

    return Dialog(
      backgroundColor: const Color.fromARGB(255, 21, 29, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        width: 800.w,
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title.
              Text(
                l10n.bulkExport,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
              ),
              SizedBox(height: 24.h),
              // Main Content Container.
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 28, 36, 46),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dataInfo,
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
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            context: context,
                            title: l10n.availability,
                            hint: l10n.select,
                            items: availabilityOptions,
                            isArabic: isArabic,
                            isRtl: isRtl,
                            onChanged: (value) {
                              setState(() {
                                // When "All" is chosen, clear filter (set to null).
                                if (value == l10n.all) {
                                  _selectedAvailability = null;
                                } else {
                                  _selectedAvailability = value;
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: _buildDropdownField(
                            context: context,
                            title: l10n.category,
                            hint: l10n.select,
                            items: _getCategoryList(),
                            isArabic: isArabic,
                            isRtl: isRtl,
                            onChanged: (value) {
                              setState(() {
                                if (value == l10n.all) {
                                  _selectedCategory = null;
                                } else {
                                  _selectedCategory = value;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumericTextField(
                            context: context,
                            title: l10n.priceFrom,
                            hint: '0',
                            controller: _priceFromController,
                            isArabic: isArabic,
                            isRtl: isRtl,
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: _buildNumericTextField(
                            context: context,
                            title: l10n.priceTo,
                            hint: '0',
                            controller: _priceToController,
                            hasInfinityOption: true,
                            isArabic: isArabic,
                            isRtl: isRtl,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 28, 36, 46),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32.w, vertical: 20.h),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 105, 123, 123),
                                width: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.cancel,
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
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 105, 65, 198),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 32.w, vertical: 20.h),
                          ),
                          onPressed: _onSubmit,
                          child: Text(
                            l10n.submit,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bottom Buttons.
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a numeric text field with an optional infinity option (for Price To).
  Widget _buildNumericTextField({
    required BuildContext context,
    required String title,
    required String hint,
    required TextEditingController controller,
    required bool isArabic,
    required bool isRtl,
    bool hasInfinityOption = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 42, 54, 69)),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: isArabic
                ? GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: Colors.white,
                  )
                : GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: isArabic
                  ? GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14.sp,
                    )
                  : GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
              suffixIcon: hasInfinityOption
                  ? IconButton(
                      icon: Text(
                        "∞",
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 16.sp,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                      ),
                      onPressed: () {
                        setState(() {
                          controller.text = "∞";
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a generic dropdown field with label.
  Widget _buildDropdownField({
    required BuildContext context,
    required String title,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isArabic,
    required bool isRtl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
        SizedBox(height: 6.h),
        Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 42, 54, 69)),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonFormField<String>(
              iconSize: 20.sp,
              iconEnabledColor: Colors.white70,
              dropdownColor: const Color.fromARGB(255, 36, 50, 69),
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
              hint: Text(
                hint, // e.g. "Select"
                style: isArabic
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                hintText: hint,
                hintStyle: isArabic
                    ? GoogleFonts.cairo(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14.sp,
                      ),
              ),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
