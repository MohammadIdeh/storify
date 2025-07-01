import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/rolesWidgets/role_item.dart';

class RolesTable extends StatefulWidget {
  final List<RoleItem> roles;
  final String filter;
  final String searchQuery;
  final Function(RoleItem role)? onDeleteRole;
  final Future<bool> Function(String id) onDeleteUser;
  final Function(RoleItem updatedRole)? onEditRole;
  final Function(RoleItem role)?
      onToggleActiveStatus; // New callback for switch

  const RolesTable({
    super.key,
    required this.roles,
    this.filter = "All Users",
    this.searchQuery = "",
    this.onDeleteRole,
    required this.onDeleteUser,
    this.onEditRole,
    this.onToggleActiveStatus, // Add this parameter
  });

  @override
  State<RolesTable> createState() => _RolesTableState();
}

class _RolesTableState extends State<RolesTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 8; // Reduced for better UX
  Set<String> _processingUsers = {}; // Track users being processed

  /// Filters roles based on the filter string and search query
  List<RoleItem> get _filteredRoles {
    List<RoleItem> filtered = widget.roles;

    // Filter by role
    if (widget.filter != "All Users") {
      filtered = filtered
          .where((roleItem) =>
              roleItem.role.toLowerCase() == widget.filter.toLowerCase())
          .toList();
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
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.withOpacity(0.8);
      case 'warehouseemployee':
        return Colors.blue.withOpacity(0.8);
      case 'customer':
        return Colors.green.withOpacity(0.8);
      case 'supplier':
        return Colors.orange.withOpacity(0.8);
      case 'deliveryemployee':
        return Colors.purple.withOpacity(0.8);
      default:
        return Colors.grey.withOpacity(0.8);
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'warehouseemployee':
        return 'Warehouse Employee';
      case 'deliveryemployee':
        return 'Delivery Employee';
      default:
        return role;
    }
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatRole(role),
        style: GoogleFonts.spaceGrotesk(
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredRoles;
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Container(
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
                  "Users Overview",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 105, 65, 198)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$totalItems Total",
                    style: GoogleFonts.spaceGrotesk(
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
          if (_visibleRoles.isEmpty)
            Container(
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
                      "No users found",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        color: Colors.white54,
                      ),
                    ),
                    if (widget.searchQuery.isNotEmpty)
                      Text(
                        "Try adjusting your search criteria",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.sp,
                          color: Colors.white38,
                        ),
                      ),
                  ],
                ),
              ),
            )
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
                  headingTextStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  dataTextStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.sp,
                  ),
                  columns: const [
                    DataColumn(label: Text("User ID")),
                    DataColumn(label: Text("User Info")),
                    DataColumn(label: Text("Contact")),
                    DataColumn(label: Text("Registration")),
                    DataColumn(label: Text("Role")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Actions")),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#${roleItem.userId}",
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 105, 65, 198),
                              ),
                            ),
                          ),
                        ),

                        // User Info
                        DataCell(
                          Row(
                            children: [
                              // Profile Picture or Initials
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 105, 65, 198)
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
                                            // Fallback to initials if image fails to load
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
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: const Color.fromARGB(
                                                        255, 105, 65, 198),
                                                    fontWeight: FontWeight.bold,
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
                                                    color: const Color.fromARGB(
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
                                                ? roleItem.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: const Color.fromARGB(
                                                  255, 105, 65, 198),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      roleItem.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      roleItem.email,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white54,
                                        fontSize: 11.sp,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contact
                        DataCell(
                          Column(
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
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.sp),
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
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10.sp,
                                          color: Colors.white54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                roleItem.dateAdded.split(' ')[1],
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.sp,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Role
                        DataCell(_buildRoleBadge(roleItem.role)),

                        // Active Status Switch
                        DataCell(
                          Row(
                            children: [
                              if (isProcessing)
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color.fromARGB(255, 105, 65, 198),
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
                                      if (widget.onToggleActiveStatus != null) {
                                        setState(() {
                                          _processingUsers.add(roleItem.userId);
                                        });

                                        await widget
                                            .onToggleActiveStatus!(roleItem);

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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: roleItem.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  roleItem.isActive ? "Active" : "Inactive",
                                  style: GoogleFonts.spaceGrotesk(
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

                        // Actions
                        DataCell(
                          Row(
                            children: [
                              // Edit Button
                              _buildActionButton(
                                icon: Icons.edit_outlined,
                                color: Colors.blue,
                                tooltip: "Edit User",
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
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          // Pagination
          if (totalPages > 1)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 41, 56, 77),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Showing ${((_currentPage - 1) * _itemsPerPage) + 1}-${_currentPage * _itemsPerPage > totalItems ? totalItems : _currentPage * _itemsPerPage} of $totalItems users",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),

                  // Previous Button
                  IconButton(
                    icon: Icon(Icons.chevron_left,
                        size: 20.sp, color: Colors.white70),
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
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentPage = pageIndex;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
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
                            style: GoogleFonts.spaceGrotesk(
                              color: isSelected ? Colors.white : Colors.white70,
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
                    icon: Icon(Icons.chevron_right,
                        size: 20.sp, color: Colors.white70),
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
        ],
      ),
    );
  }
}
