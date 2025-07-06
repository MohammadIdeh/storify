import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/rolesWidgets/role_item.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class RolesTable extends StatefulWidget {
  final List<RoleItem> roles;
  final String filter;
  final String searchQuery;
  final Function(RoleItem role)? onDeleteRole;
  final Future<bool> Function(String id) onDeleteUser;
  final Function(RoleItem updatedRole)? onEditRole;
  final Function(RoleItem role)? onToggleActiveStatus;
  final bool isLoading;

  const RolesTable({
    super.key,
    required this.roles,
    this.filter = "All Users",
    this.searchQuery = "",
    this.onDeleteRole,
    required this.onDeleteUser,
    this.onEditRole,
    this.onToggleActiveStatus,
    this.isLoading = false,
  });

  @override
  State<RolesTable> createState() => _RolesTableState();
}

class _RolesTableState extends State<RolesTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 8;
  Set<String> _processingUsers = {};

  /// Filters roles based on the filter string and search query
  List<RoleItem> get _filteredRoles {
    final l10n = context.l10n;
    List<RoleItem> filtered = widget.roles;

    // Filter by role - handle both localized and API role names
    if (widget.filter != l10n.allUsers) {
      filtered = filtered.where((roleItem) {
        // Direct comparison with display role
        if (roleItem.role == widget.filter) return true;

        // Also check if the filter matches any of the localized role names
        return _roleMatches(roleItem.role, widget.filter, l10n);
      }).toList();
    }

    // Filter by search query
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((roleItem) =>
              roleItem.userId
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()) ||
              roleItem.name
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()) ||
              roleItem.email
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()))
          .toList();

      // Sort by relevance
      filtered.sort((a, b) {
        bool aIdStarts =
            a.userId.toLowerCase().startsWith(widget.searchQuery.toLowerCase());
        bool bIdStarts =
            b.userId.toLowerCase().startsWith(widget.searchQuery.toLowerCase());
        bool aNameStarts =
            a.name.toLowerCase().startsWith(widget.searchQuery.toLowerCase());
        bool bNameStarts =
            b.name.toLowerCase().startsWith(widget.searchQuery.toLowerCase());

        if (aIdStarts && !bIdStarts) return -1;
        if (!aIdStarts && bIdStarts) return 1;
        if (aNameStarts && !bNameStarts) return -1;
        if (!aNameStarts && bNameStarts) return 1;
        return 0;
      });
    }

    return filtered;
  }

  /// Helper method to check if a role matches the filter
  bool _roleMatches(String roleToCheck, String filter, AppLocalizations l10n) {
    // Direct match
    if (roleToCheck.toLowerCase() == filter.toLowerCase()) return true;

    // Check all possible role translations
    Map<String, String> roleMap = {
      l10n.admin: "admin",
      l10n.warehouseEmployee: "warehouseemployee",
      l10n.customer: "customer",
      l10n.supplier: "supplier",
      l10n.deliveryEmployee: "deliveryemployee",
    };

    // Check if the role or filter matches any translation
    for (var entry in roleMap.entries) {
      if ((roleToCheck == entry.key && filter == entry.key) ||
          (roleToCheck.toLowerCase() == entry.value && filter == entry.key) ||
          (roleToCheck == entry.key && filter.toLowerCase() == entry.value)) {
        return true;
      }
    }

    return false;
  }

  List<RoleItem> get _visibleRoles {
    final filteredList = _filteredRoles;
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;

    return filteredList.sublist(startIndex, endIndex);
  }

  Color _getRoleColor(String role) {
    final l10n = context.l10n;

    // Normalize role for comparison
    String normalizedRole = role.toLowerCase();

    if (normalizedRole == 'admin' || role == l10n.admin) {
      return Colors.red.withOpacity(0.8);
    } else if (normalizedRole == 'warehouseemployee' ||
        role == l10n.warehouseEmployee) {
      return Colors.blue.withOpacity(0.8);
    } else if (normalizedRole == 'customer' || role == l10n.customer) {
      return Colors.green.withOpacity(0.8);
    } else if (normalizedRole == 'supplier' || role == l10n.supplier) {
      return Colors.orange.withOpacity(0.8);
    } else if (normalizedRole == 'deliveryemployee' ||
        role == l10n.deliveryEmployee) {
      return Colors.purple.withOpacity(0.8);
    }
    return Colors.grey.withOpacity(0.8);
  }

  String _formatRole(String role) {
    // Role should already be localized when coming from the main screen
    return role;
  }

  Widget _buildRoleBadge(String role, bool isArabic) {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatRole(role),
        style: isArabic
            ? GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              )
            : GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isArabic) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(40.w),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color.fromARGB(255, 105, 65, 198),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.loadingUsers,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.pleaseWaitWhileWeFetchUserData,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: Colors.white54,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white54,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(40.w),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48.sp,
              color: Colors.white38,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noUsersFound,
              style: isArabic
                  ? GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
            ),
            if (widget.searchQuery.isNotEmpty)
              Text(
                l10n.tryAdjustingYourSearchCriteria,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      ),
              )
            else
              Text(
                l10n.noUsersHaveBeenAddedYet,
                style: isArabic
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = context.isArabic;
    final isRTL = context.isRTL;

    final filteredList = _filteredRoles;
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromARGB(255, 105, 65, 198).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 45, 62, 85),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: const Color.fromARGB(255, 105, 65, 198),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.usersOverview,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 105, 65, 198)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.isLoading
                          ? l10n.loading
                          : "${totalItems} ${l10n.total}",
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 105, 65, 198),
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 105, 65, 198),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Content
            if (widget.isLoading)
              _buildLoadingState(isArabic)
            else if (_visibleRoles.isEmpty)
              _buildEmptyState(isArabic)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 90.w,
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 41, 56, 77),
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => Colors.transparent,
                    ),
                    headingRowHeight: 50.h,
                    dataRowHeight: 65.h,
                    columnSpacing: 20.w,
                    dividerThickness: 1,
                    headingTextStyle: isArabic
                        ? GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    dataTextStyle: isArabic
                        ? GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12.sp,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12.sp,
                          ),
                    columns: [
                      DataColumn(label: Text(l10n.userId)),
                      DataColumn(label: Text(l10n.userInfo)),
                      DataColumn(label: Text(l10n.contact)),
                      DataColumn(label: Text(l10n.registration)),
                      DataColumn(label: Text(l10n.role)),
                      DataColumn(label: Text(l10n.status)),
                      DataColumn(label: Text(l10n.actions)),
                    ],
                    rows: _visibleRoles.map((roleItem) {
                      final isProcessing =
                          _processingUsers.contains(roleItem.userId);

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (states) => Colors.white.withOpacity(0.02),
                        ),
                        cells: [
                          // User ID
                          DataCell(
                            Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 105, 65, 198)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "#${roleItem.userId}",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 105, 65, 198),
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 105, 65, 198),
                                      ),
                              ),
                            ),
                          ),

                          // User Info
                          DataCell(
                            Directionality(
                              textDirection:
                                  isRTL ? TextDirection.rtl : TextDirection.ltr,
                              child: Row(
                                children: [
                                  // Profile Picture or Initials
                                  Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                                255, 105, 65, 198)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: roleItem.profilePicture != null &&
                                            roleItem.profilePicture!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              roleItem.profilePicture!,
                                              width: 32.w,
                                              height: 32.w,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 32.w,
                                                  height: 32.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color.fromARGB(
                                                            255, 105, 65, 198)
                                                        .withOpacity(0.2),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      roleItem.name.isNotEmpty
                                                          ? roleItem.name[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: isArabic
                                                          ? GoogleFonts.cairo(
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  105, 65, 198),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14.sp,
                                                            )
                                                          : GoogleFonts
                                                              .spaceGrotesk(
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  105, 65, 198),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14.sp,
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: 32.w,
                                                  height: 32.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color.fromARGB(
                                                            255, 105, 65, 198)
                                                        .withOpacity(0.1),
                                                  ),
                                                  child: Center(
                                                    child: SizedBox(
                                                      width: 16.w,
                                                      height: 16.w,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 105, 65, 198),
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 32.w,
                                            height: 32.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color.fromARGB(
                                                      255, 105, 65, 198)
                                                  .withOpacity(0.2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                roleItem.name.isNotEmpty
                                                    ? roleItem.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: isArabic
                                                    ? GoogleFonts.cairo(
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 105, 65, 198),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.sp,
                                                      )
                                                    : GoogleFonts.spaceGrotesk(
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 105, 65, 198),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.sp,
                                                      ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          roleItem.name,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.sp,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.sp,
                                                ),
                                          overflow: TextOverflow.ellipsis,
                                          textDirection: isRTL
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                        ),
                                        Text(
                                          roleItem.email,
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  color: Colors.white54,
                                                  fontSize: 11.sp,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  color: Colors.white54,
                                                  fontSize: 11.sp,
                                                ),
                                          overflow: TextOverflow.ellipsis,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Contact
                          DataCell(
                            Directionality(
                              textDirection:
                                  isRTL ? TextDirection.rtl : TextDirection.ltr,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 12.sp, color: Colors.white54),
                                      SizedBox(width: 4.w),
                                      Text(
                                        roleItem.phoneNo,
                                        style: isArabic
                                            ? GoogleFonts.cairo(fontSize: 11.sp)
                                            : GoogleFonts.spaceGrotesk(
                                                fontSize: 11.sp),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                  if (roleItem.address != null &&
                                      roleItem.address!.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 12.sp, color: Colors.white54),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            roleItem.address!,
                                            style: isArabic
                                                ? GoogleFonts.cairo(
                                                    fontSize: 10.sp,
                                                    color: Colors.white54,
                                                  )
                                                : GoogleFonts.spaceGrotesk(
                                                    fontSize: 10.sp,
                                                    color: Colors.white54,
                                                  ),
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: isRTL
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Registration Date
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  roleItem.dateAdded.split(' ')[0],
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  textDirection: TextDirection.ltr,
                                ),
                                Text(
                                  roleItem.dateAdded.split(' ')[1],
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          fontSize: 10.sp,
                                          color: Colors.white54,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          fontSize: 10.sp,
                                          color: Colors.white54,
                                        ),
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),

                          // Role
                          DataCell(_buildRoleBadge(roleItem.role, isArabic)),

                          // Active Status Switch
                          DataCell(
                            Directionality(
                              textDirection:
                                  isRTL ? TextDirection.rtl : TextDirection.ltr,
                              child: Row(
                                children: [
                                  if (isProcessing)
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Color.fromARGB(255, 105, 65, 198),
                                      ),
                                    )
                                  else
                                    Transform.scale(
                                      scale: 0.8,
                                      child: CupertinoSwitch(
                                        value: roleItem.isActive,
                                        activeColor: Colors.green,
                                        trackColor: Colors.red.withOpacity(0.3),
                                        onChanged: (value) async {
                                          if (widget.onToggleActiveStatus !=
                                              null) {
                                            setState(() {
                                              _processingUsers
                                                  .add(roleItem.userId);
                                            });

                                            await widget.onToggleActiveStatus!(
                                                roleItem);

                                            setState(() {
                                              _processingUsers
                                                  .remove(roleItem.userId);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: roleItem.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleItem.isActive
                                          ? l10n.active
                                          : l10n.inactive,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w500,
                                              color: roleItem.isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w500,
                                              color: roleItem.isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Actions
                          DataCell(
                            Directionality(
                              textDirection:
                                  isRTL ? TextDirection.rtl : TextDirection.ltr,
                              child: Row(
                                children: [
                                  // Edit Button
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    tooltip: l10n.editUser,
                                    onTap: () {
                                      if (widget.onEditRole != null) {
                                        widget.onEditRole!(roleItem);
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Pagination
            if (!widget.isLoading && totalPages > 1)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 41, 56, 77),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    children: [
                      Text(
                        "${l10n.showing} ${((_currentPage - 1) * _itemsPerPage) + 1}-${_currentPage * _itemsPerPage > totalItems ? totalItems : _currentPage * _itemsPerPage} ${l10n.offf} $totalItems ${l10n.users}",
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
                      const Spacer(),

                      // Previous Button
                      IconButton(
                        icon: Icon(
                            isRTL ? Icons.chevron_right : Icons.chevron_left,
                            size: 20.sp,
                            color: Colors.white70),
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),

                      // Page Numbers
                      ...List.generate(totalPages, (index) {
                        final pageIndex = index + 1;
                        final bool isSelected = (pageIndex == _currentPage);

                        return Padding(
                          padding:
                              EdgeInsetsDirectional.symmetric(horizontal: 2.w),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _currentPage = pageIndex;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color.fromARGB(255, 105, 65, 198)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color.fromARGB(255, 105, 65, 198)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                "$pageIndex",
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Next Button
                      IconButton(
                        icon: Icon(
                            isRTL ? Icons.chevron_left : Icons.chevron_right,
                            size: 20.sp,
                            color: Colors.white70),
                        onPressed: _currentPage < totalPages
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
