import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/widgets/rolesWidgets/role_item.dart';
import 'package:storify/admin/widgets/rolesWidgets/rolesTable.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:storify/providers/LocalizationHelper.dart';

class Rolemanegment extends StatefulWidget {
  const Rolemanegment({super.key});

  @override
  State<Rolemanegment> createState() => _RolemanegmentState();
}

class _RolemanegmentState extends State<Rolemanegment> {
  int _currentIndex = 4;
  int _selectedFilterIndex = 0;
  String _searchQuery = "";
  String? profilePictureUrl;
  bool _isLoading = false;

  List<String> _filters = [];
  List<RoleItem> _roleList = [];

  final String getUsersApi =
      "https://finalproject-a5ls.onrender.com/auth/users";
  final String addUserApi =
      "https://finalproject-a5ls.onrender.com/auth/register";

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeFilters();
    if (_roleList.isEmpty && !_isLoading) {
      _fetchUsers();
    }
  }

  void _initializeFilters() {
    final l10n = context.l10n;
    _filters = [
      l10n.allUsers,
      l10n.admin,
      l10n.warehouseEmployee,
      l10n.customer,
      l10n.supplier,
      l10n.deliveryEmployee
    ];
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Updated to handle Active/NotActive format
  Future<RoleItem?> _updateUser(RoleItem updatedUser) async {
    final l10n = context.l10n;

    try {
      setState(() => _isLoading = true);

      final url = Uri.parse(
          "https://finalproject-a5ls.onrender.com/auth/${updatedUser.userId}");

      // Convert localized role to API role
      final apiRole = _getApiRoleFromDisplay(updatedUser.role);

      final bodyMap = {
        "name": updatedUser.name,
        "email": updatedUser.email,
        "phoneNumber": updatedUser.phoneNo,
        "roleName": apiRole,
        "isActive": updatedUser.isActive ? "Active" : "NotActive",
      };

      if (apiRole.toLowerCase() == "customer" &&
          updatedUser.address != null &&
          updatedUser.address!.isNotEmpty) {
        bodyMap["address"] = updatedUser.address!;
      }

      final body = jsonEncode(bodyMap);
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return updatedUser.copyWith(
          dateAdded: DateFormat("MM-dd-yyyy HH:mm").format(DateTime.now()),
        );
      } else {
        throw Exception("${l10n.failedToUpdateUser}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating user: $e");
      _showErrorSnackBar("${l10n.failedToUpdateUser}: $e");
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper method to convert display role to API role
  String _getApiRoleFromDisplay(String displayRole) {
    final l10n = context.l10n;

    if (displayRole == l10n.admin) return "Admin";
    if (displayRole == l10n.warehouseEmployee) return "WarehouseEmployee";
    if (displayRole == l10n.customer) return "Customer";
    if (displayRole == l10n.supplier) return "Supplier";
    if (displayRole == l10n.deliveryEmployee) return "DeliveryEmployee";

    return displayRole; // fallback
  }

  // Helper method to convert API role to display role
  String _getDisplayRoleFromApi(String apiRole) {
    final l10n = context.l10n;

    switch (apiRole.toLowerCase()) {
      case "admin":
        return l10n.admin;
      case "employee":
        return l10n.warehouseEmployee;
      case "customer":
        return l10n.customer;
      case "supplier":
        return l10n.supplier;
      case "delivery":
        return l10n.deliveryEmployee;
      default:
        return apiRole;
    }
  }

  // New method to handle switch toggle
  Future<void> _toggleUserActiveStatus(RoleItem user) async {
    final l10n = context.l10n;

    final updatedUser = user.copyWith(isActive: !user.isActive);
    final result = await _updateUser(updatedUser);

    if (result != null) {
      setState(() {
        final index = _roleList.indexWhere((r) => r.userId == user.userId);
        if (index != -1) {
          _roleList[index] = result;
        }
      });
      _showSuccessSnackBar(l10n.userStatusUpdatedSuccessfully);
    }
  }

  Future<bool> _deleteUser(String userId) async {
    final l10n = context.l10n;

    try {
      setState(() => _isLoading = true);

      final url =
          Uri.parse("https://finalproject-a5ls.onrender.com/auth/$userId");
      final response = await http.delete(url, headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessSnackBar(l10n.userDeletedSuccessfully);
        return true;
      } else {
        _showErrorSnackBar(l10n.failedToDeleteUser);
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting user: $e");
      _showErrorSnackBar("${l10n.errorDeletingUser}: $e");
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(getUsersApi),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        List<dynamic> data = [];

        if (decodedJson is Map<String, dynamic> &&
            decodedJson.containsKey("users")) {
          data = decodedJson["users"] ?? [];
        } else if (decodedJson is List) {
          data = decodedJson;
        } else {
          throw Exception(
              "The API did not return the expected JSON structure.");
        }

        List<RoleItem> loadedUsers = data.map((json) {
          return RoleItem(
            userId: json['userId'].toString(),
            name: json['name'] ?? "",
            email: json['email'] ?? "",
            phoneNo: json['phoneNumber'] ?? "",
            dateAdded: DateFormat("MM-dd-yyyy HH:mm")
                .format(DateTime.parse(json['registrationDate'])),
            role: _getDisplayRoleFromApi(json['roleName'] ?? ""),
            isActive: parseIsActive(json['isActive']),
            address: json['address'] ?? "",
            profilePicture: json['profilePicture'],
          );
        }).toList();

        setState(() {
          _roleList = loadedUsers;
        });

        debugPrint("Fetched ${_roleList.length} users");
      } else {
        throw Exception("Failed to fetch users: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) {
        _showErrorSnackBar("Failed to load users: $e");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/admin/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/admin/products');
        break;
      case 2:
        Navigator.pushNamed(context, '/admin/categories');
        break;
      case 3:
        Navigator.pushNamed(context, '/admin/orders');
        break;
      case 4:
        // Current Role Management screen - no navigation needed
        break;
      case 5:
        Navigator.pushNamed(context, '/admin/tracking');
        break;
    }
  }

  // Updated dialog with non-editable role during edit
  Future<RoleItem?> _showUserDialog({RoleItem? roleToEdit}) async {
    final l10n = context.l10n;
    final isArabic = context.isArabic;
    final isRTL = context.isRTL;

    final nameController = TextEditingController(text: roleToEdit?.name ?? "");
    final emailController =
        TextEditingController(text: roleToEdit?.email ?? "");
    final phoneController =
        TextEditingController(text: roleToEdit?.phoneNo ?? "");
    final addressController =
        TextEditingController(text: roleToEdit?.address ?? "");

    String selectedRole = roleToEdit?.role ?? _filters[1];
    bool localIsActive = roleToEdit?.isActive ?? true;
    bool isEditMode = roleToEdit != null;

    return showDialog<RoleItem>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Center(
            child: SizedBox(
              width: 580.w,
              child: Dialog(
                backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 24.w, vertical: 24.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 105, 65, 198),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditMode ? Icons.edit : Icons.person_add,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              isEditMode ? l10n.editUser : l10n.addNewUser,
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
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Name Field
                        _buildInputField(
                          controller: nameController,
                          label: l10n.fullName,
                          icon: Icons.person_outline,
                          isArabic: isArabic,
                          isRTL: isRTL,
                        ),
                        SizedBox(height: 16.h),

                        // Email Field
                        _buildInputField(
                          controller: emailController,
                          label: l10n.emailAddress,
                          icon: Icons.email_outlined,
                          enabled: !isEditMode,
                          isArabic: isArabic,
                          isRTL: isRTL,
                        ),
                        SizedBox(height: 16.h),

                        // Phone Field
                        _buildInputField(
                          controller: phoneController,
                          label: l10n.phoneNumber,
                          icon: Icons.phone_outlined,
                          isArabic: isArabic,
                          isRTL: isRTL,
                        ),
                        SizedBox(height: 16.h),

                        // Address Field
                        _buildInputField(
                          controller: addressController,
                          label: selectedRole == l10n.customer
                              ? l10n.addressRequired
                              : l10n.addressOptional,
                          icon: Icons.location_on_outlined,
                          isArabic: isArabic,
                          isRTL: isRTL,
                        ),
                        SizedBox(height: 16.h),

                        // Role Dropdown - Disabled during edit
                        Container(
                          decoration: BoxDecoration(
                            color: isEditMode
                                ? const Color.fromARGB(255, 45, 62, 85)
                                    .withOpacity(0.5)
                                : const Color.fromARGB(255, 45, 62, 85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedRole,
                            dropdownColor:
                                const Color.fromARGB(255, 36, 50, 69),
                            style: isArabic
                                ? GoogleFonts.cairo(color: Colors.white)
                                : GoogleFonts.spaceGrotesk(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.role,
                              labelStyle: isArabic
                                  ? GoogleFonts.cairo(
                                      color: isEditMode
                                          ? Colors.white38
                                          : Colors.white70)
                                  : GoogleFonts.spaceGrotesk(
                                      color: isEditMode
                                          ? Colors.white38
                                          : Colors.white70),
                              prefixIcon: Icon(
                                Icons.admin_panel_settings_outlined,
                                color: isEditMode
                                    ? Colors.white38
                                    : const Color.fromARGB(255, 105, 65, 198),
                                size: 20.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 16.w, vertical: 16.h),
                            ),
                            items: _filters
                                .where((role) => role != l10n.allUsers)
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: isEditMode
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setStateDialog(() {
                                        selectedRole = val;
                                      });
                                    }
                                  },
                          ),
                        ),

                        if (isEditMode) ...[
                          SizedBox(height: 8.h),
                          Text(
                            l10n.roleCannotBeChangedDuringEdit,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    color: Colors.orange.withOpacity(0.8),
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.orange.withOpacity(0.8),
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                          ),
                        ],

                        SizedBox(height: 20.h),

                        // Active Status Switch
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 45, 62, 85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.toggle_on_outlined,
                                color: const Color.fromARGB(255, 105, 65, 198),
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.accountStatus,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                    ),
                                    Text(
                                      localIsActive
                                          ? l10n.active
                                          : l10n.inactive,
                                      style: isArabic
                                          ? GoogleFonts.cairo(
                                              color: localIsActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12.sp,
                                            )
                                          : GoogleFonts.spaceGrotesk(
                                              color: localIsActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12.sp,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: localIsActive,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      localIsActive = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                      color: Colors.white54, width: 1.5),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  l10n.cancel,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white70,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white70,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                onPressed: () {
                                  if (_validateForm(
                                      nameController,
                                      emailController,
                                      phoneController,
                                      addressController,
                                      selectedRole)) {
                                    final newRole = RoleItem(
                                      userId: roleToEdit?.userId ??
                                          "new_${DateTime.now().millisecondsSinceEpoch}",
                                      name: nameController.text.trim(),
                                      email: emailController.text.trim(),
                                      phoneNo: phoneController.text.trim(),
                                      dateAdded: DateFormat("MM-dd-yyyy HH:mm")
                                          .format(DateTime.now()),
                                      role: selectedRole,
                                      address: selectedRole == l10n.customer
                                          ? addressController.text.trim()
                                          : (addressController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? addressController.text.trim()
                                              : null),
                                      isActive: localIsActive,
                                      profilePicture:
                                          roleToEdit?.profilePicture,
                                    );
                                    Navigator.pop(ctx, newRole);
                                  }
                                },
                                child: Text(
                                  isEditMode
                                      ? l10n.updateUser
                                      : l10n.createUser,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    required bool isArabic,
    required bool isRTL,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color.fromARGB(255, 45, 62, 85)
            : const Color.fromARGB(255, 45, 62, 85).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 105, 65, 198).withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        // textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        style: isArabic
            ? GoogleFonts.cairo(color: enabled ? Colors.white : Colors.white54)
            : GoogleFonts.spaceGrotesk(
                color: enabled ? Colors.white : Colors.white54),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: isArabic
              ? GoogleFonts.cairo(
                  color: enabled ? Colors.white70 : Colors.white38)
              : GoogleFonts.spaceGrotesk(
                  color: enabled ? Colors.white70 : Colors.white38),
          prefixIcon: Icon(
            icon,
            color: enabled
                ? const Color.fromARGB(255, 105, 65, 198)
                : Colors.white38,
            size: 20.sp,
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  bool _validateForm(
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    String selectedRole,
  ) {
    final l10n = context.l10n;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      _showErrorSnackBar(l10n.pleaseFillAllRequiredFields);
      return false;
    }

    if (selectedRole == l10n.customer &&
        addressController.text.trim().isEmpty) {
      _showErrorSnackBar(l10n.addressIsRequiredForCustomers);
      return false;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      _showErrorSnackBar(l10n.pleaseEnterValidEmailAddress);
      return false;
    }

    return true;
  }

  void _handleAddUser() async {
    final l10n = context.l10n;

    final newUser = await _showUserDialog();
    if (newUser != null) {
      final addedUser = await _addUser(newUser);
      if (addedUser != null) {
        setState(() {
          _roleList.add(addedUser);
        });
        _showSuccessSnackBar(l10n.userAddedSuccessfully);
      }
    }
  }

  void _handleEditUser(RoleItem role) async {
    final l10n = context.l10n;

    final updatedUser = await _showUserDialog(roleToEdit: role);
    if (updatedUser != null) {
      final resultUser = await _updateUser(updatedUser);
      if (resultUser != null) {
        setState(() {
          final index = _roleList.indexWhere((r) => r.userId == role.userId);
          if (index != -1) {
            _roleList[index] = resultUser;
          }
        });
        _showSuccessSnackBar(l10n.userUpdatedSuccessfully);
      }
    }
  }

  Future<RoleItem?> _addUser(RoleItem newUser) async {
    final l10n = context.l10n;

    try {
      setState(() => _isLoading = true);

      final url = Uri.parse(addUserApi);

      // Convert display role to API role
      final apiRole = _getApiRoleFromDisplay(newUser.role);

      final bodyMap = {
        "name": newUser.name,
        "email": newUser.email,
        "phoneNumber": newUser.phoneNo,
        "roleName": apiRole,
        "isActive": newUser.isActive ? "Active" : "NotActive",
      };

      if (apiRole.toLowerCase() == "customer" &&
          newUser.address != null &&
          newUser.address!.isNotEmpty) {
        bodyMap["address"] = newUser.address!;
      }

      final body = jsonEncode(bodyMap);
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final newUserId = json["user"]["id"].toString();
        return newUser.copyWith(
          userId: newUserId,
          dateAdded: DateFormat("MM-dd-yyyy HH:mm").format(DateTime.now()),
        );
      } else {
        throw Exception("${l10n.failedToAddUser}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error adding user: $e");
      _showErrorSnackBar("${l10n.failedToAddUser}: $e");
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFilterChip(String label, int index, bool isArabic) {
    final bool isSelected = (_selectedFilterIndex == index);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            EdgeInsetsDirectional.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 105, 65, 198)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 230, 230, 230),
                )
              : GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 230, 230, 230),
                ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final isArabic = context.isArabic;
    final isRTL = context.isRTL;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white)
                    : GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final isArabic = context.isArabic;
    final isRTL = context.isRTL;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: isArabic
                    ? GoogleFonts.cairo(color: Colors.white)
                    : GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = context.isArabic;
    final isRTL = context.isRTL;

    String headerText = _selectedFilterIndex == 0
        ? l10n.userManagement
        : isArabic
            ? "${l10n.management} ${_filters.isNotEmpty && _selectedFilterIndex < _filters.length ? _filters[_selectedFilterIndex] : ''}"
            : "${_filters.isNotEmpty && _selectedFilterIndex < _filters.length ? _filters[_selectedFilterIndex] : ''} ${l10n.management}";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding:
                  EdgeInsetsDirectional.only(start: 45.w, top: 20.h, end: 45.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerText,
                              style: isArabic
                                  ? GoogleFonts.cairo(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )
                                  : GoogleFonts.spaceGrotesk(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              l10n.manageAndMonitorAllUserAccounts,
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
                          ],
                        ),
                        const Spacer(),

                        // Search box
                        Container(
                          width: 320.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 36, 50, 69),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 105, 65, 198)
                                  .withOpacity(0.3),
                            ),
                          ),
                          padding:
                              EdgeInsetsDirectional.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white70,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  // textDirection: isRTL
                                  //     ? TextDirection.rtl
                                  //     : TextDirection.ltr,
                                  style: isArabic
                                      ? GoogleFonts.cairo(color: Colors.white)
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: l10n.searchByUserIdOrUserName,
                                    hintStyle: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.white54)
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.white54),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // Add User Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 105, 65, 198),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 20.w, vertical: 20.h),
                            elevation: 2,
                          ),
                          onPressed: _handleAddUser,
                          icon: Icon(Icons.person_add, size: 18.sp),
                          label: Text(
                            l10n.addUser,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Filter Chips
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(255, 105, 65, 198)
                            .withOpacity(0.2),
                      ),
                    ),
                    padding: EdgeInsets.all(16.w),
                    child: Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: List.generate(_filters.length, (index) {
                        return _buildFilterChip(
                            _filters[index], index, isArabic);
                      }),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Users Table
                  RolesTable(
                    roles: _roleList,
                    filter: _filters.isNotEmpty &&
                            _selectedFilterIndex < _filters.length
                        ? _filters[_selectedFilterIndex]
                        : "",
                    isLoading: _isLoading,
                    searchQuery: _searchQuery,
                    onDeleteRole: (role) {
                      setState(() {
                        _roleList.removeWhere((r) => r.userId == role.userId);
                      });
                    },
                    onDeleteUser: _deleteUser,
                    onEditRole: _handleEditUser,
                    onToggleActiveStatus: _toggleUserActiveStatus,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated helper function to handle Active/NotActive
bool parseIsActive(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == "active";
  }
  return false;
}
