import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class SuppliersList extends StatelessWidget {
  final List<dynamic> suppliers;

  const SuppliersList({
    Key? key,
    required this.suppliers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsetsDirectional.all(20.r),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.suppliers,
                      style: isArabic 
                          ? GoogleFonts.cairo(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 105, 65, 198).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        "${suppliers.length} ${l10n.suppliersCount}",
                        style: isArabic 
                            ? GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: Color.fromARGB(255, 105, 65, 198),
                                fontWeight: FontWeight.w600,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 12.sp,
                                color: Color.fromARGB(255, 105, 65, 198),
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 54, 68, 88),
                borderRadius: BorderRadius.circular(8.r),
              ),
              height: 180.h, // Slightly taller than before
              child: suppliers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noSuppliersAssigned,
                        style: isArabic 
                            ? GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsetsDirectional.symmetric(vertical: 8.h),
                      itemCount: suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = suppliers[index];
                        final user = supplier['user'] ?? {};
                        final supplierName = user['name'] ?? l10n.unknown;
                        final supplierEmail = user['email'] ?? l10n.noEmail;
                        final supplierPhone = user['phoneNumber'] ?? l10n.noPhone;
                        final supplierId = supplier['id']?.toString() ?? l10n.unknownId;

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Color.fromARGB(255, 105, 65, 198),
                            child: Text(
                              supplierName.isNotEmpty
                                  ? supplierName[0].toUpperCase()
                                  : '?',
                              style: isArabic 
                                  ? GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  supplierName,
                                  style: isArabic 
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  "${l10n.idLabel} $supplierId",
                                  style: isArabic 
                                      ? GoogleFonts.cairo(
                                          color: Colors.white70,
                                          fontSize: 10.sp,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white70,
                                          fontSize: 10.sp,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "$supplierEmail • $supplierPhone",
                            style: isArabic 
                                ? GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}