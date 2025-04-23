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
  final Future<bool> Function(String id) onDeleteUser; // New callback
  final Function(RoleItem updatedRole)? onEditRole;

  const RolesTable({
    super.key,
    required this.roles,
    this.filter = "All Users",
    this.searchQuery = "",
    this.onDeleteRole,
    required this.onDeleteUser,
    this.onEditRole,
  });

  @override
  State<RolesTable> createState() => _RolesTableState();
}

class _RolesTableState extends State<RolesTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  /// Map to store each role's active state, keyed by userId.
  final Map<String, bool> _switchStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize the switch states for each role in widget.roles.
    for (var roleItem in widget.roles) {
      _switchStates[roleItem.userId] = roleItem.isActive;
    }
  }

  // Ensure new roles are added to _switchStates when the widget updates.
  @override
  void didUpdateWidget(covariant RolesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var role in widget.roles) {
      if (!_switchStates.containsKey(role.userId)) {
        _switchStates[role.userId] = role.isActive;
      }
    }
  }
// @override
// void didUpdateWidget(covariant RolesTable oldWidget) {
//   super.didUpdateWidget(oldWidget);
//   // Update every role's switch state with the latest isActive value.
//   for (var role in widget.roles) {
//     _switchStates[role.userId] = role.isActive;
//   }
// }

  /// Filters roles based on the filter string and search query using widget.roles.
  List<RoleItem> get _filteredRoles {
    List<RoleItem> filtered = widget.roles;
    if (widget.filter != "All Users") {
      filtered = filtered
          .where((roleItem) =>
              roleItem.role.toLowerCase() == widget.filter.toLowerCase())
          .toList();
    }
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((roleItem) => roleItem.userId.contains(widget.searchQuery))
          .toList();
      filtered.sort((a, b) {
        bool aStarts =
            a.userId.toLowerCase().startsWith(widget.searchQuery.toLowerCase());
        bool bStarts =
            b.userId.toLowerCase().startsWith(widget.searchQuery.toLowerCase());
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return 0;
      });
    }
    return filtered;
  }

  List<RoleItem> get _visibleRoles {
    // print(
    //     "*************************************************************************************Visible roles count: ${_visibleRoles.length} out of ${_filteredRoles.length}");

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

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredRoles;
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide = BorderSide(
      color: const Color.fromARGB(255, 41, 56, 77),
      width: 1,
    );
    final BorderSide dividerSide2 = BorderSide(
      color: const Color.fromARGB(255, 36, 50, 69),
      width: 2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          clipBehavior: Clip.antiAlias,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor:
                        MaterialStateProperty.all<Color>(headingColor),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => Colors.transparent),
                    border: TableBorder(
                      top: dividerSide,
                      bottom: dividerSide,
                      left: dividerSide,
                      right: dividerSide,
                      horizontalInside: dividerSide2,
                      verticalInside: dividerSide2,
                    ),
                    columnSpacing: 20.w,
                    dividerThickness: 0,
                    headingTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.sp,
                    ),
                    columns: const [
                      DataColumn(label: Text("User ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Phone No")),
                      DataColumn(label: Text("Date Added")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Is Active")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: _visibleRoles.map((roleItem) {
                      return DataRow(
                        cells: [
                          DataCell(Text(roleItem.userId)),
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14.r,
                                  backgroundColor: Colors.grey.shade500,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 14.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(roleItem.name),
                              ],
                            ),
                          ),
                          DataCell(Text(roleItem.phoneNo)),
                          DataCell(Text(roleItem.dateAdded)),
                          DataCell(Text(roleItem.role)),
                          DataCell(
                            Transform.scale(
                              scale: 0.7,
                              child: AbsorbPointer(
                                child: CupertinoSwitch(
                                  value:
                                      _switchStates[roleItem.userId] ?? false,
                                  activeColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                // Edit Button
                                InkWell(
                                  onTap: () {
                                    if (widget.onEditRole != null) {
                                      widget.onEditRole!(roleItem);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Delete Button
                                InkWell(
                                  onTap: () async {
                                    // Show confirmation dialog.
                                    bool? confirmed = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: const Color.fromARGB(
                                              255, 36, 50, 69),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: Text("Confirm Deletion",
                                              style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white)),
                                          content: Text(
                                              "Are you sure you want to delete this user?",
                                              style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: Text("Cancel",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                          color:
                                                              Colors.white70)),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: Text("Confirm",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                          color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmed == true) {
                                      // Call the deletion callback from the parent.
                                      bool success = await widget
                                          .onDeleteUser(roleItem.userId);
                                      if (success) {
                                        // If deletion is successful, update the UI via the parent's onDeleteRole callback.
                                        if (widget.onDeleteRole != null) {
                                          widget.onDeleteRole!(roleItem);
                                        }
                                      } else {
                                        // Optionally, show an error message.
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "Failed to delete user",
                                                style:
                                                    GoogleFonts.spaceGrotesk()),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      "Total $totalItems Users",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          size: 20.sp, color: Colors.white70),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    Row(
                      children: List.generate(totalPages, (index) {
                        final pageIndex = index + 1;
                        final bool isSelected = (pageIndex == _currentPage);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? const Color.fromARGB(255, 105, 65, 198)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: const Color.fromARGB(255, 34, 53, 62),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 10.h),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentPage = pageIndex;
                              });
                            },
                            child: Text(
                              "$pageIndex",
                              style: GoogleFonts.spaceGrotesk(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward,
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
      },
    );
  }
}
