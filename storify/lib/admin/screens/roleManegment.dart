import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/widgets/rolesWidget/role_item.dart';
import 'package:storify/admin/widgets/rolesWidget/rolesTable.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Rolemanegment extends StatefulWidget {
  const Rolemanegment({super.key});

  @override
  State<Rolemanegment> createState() => _RolemanegmentState();
}

class _RolemanegmentState extends State<Rolemanegment> {
  int _currentIndex = 4;
  int _selectedFilterIndex = 0; // 0: All Users, 1: Admins, etc.
  String _searchQuery = "";

  final List<String> _filters = [
    "All Users",
    "Admins",
    "Employees",
    "Customers",
    "Suppliers",
    "delivery Employees"
  ];

  // This list will be populated from the API.
  List<RoleItem> _roleList = [];

  // API endpoints.
  // Make sure your API returns the fields exactly as needed for the table.
  final String getUsersApi =
      "https://ef98-86-107-17-148.ngrok-free.app/auth/users";
  final String addUserApi =
      "https://ef98-86-107-17-148.ngrok-free.app/auth/register";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse(getUsersApi),
        headers: {"Accept": "application/json"},
      );

      // Log status, headers, and body for debugging.
      print("Status code: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response body: ${response.body}");

      // Attempt to parse JSON without checking content-type.
      final decodedJson = jsonDecode(response.body);

      // Validate the structure.
      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey("users")) {
        List<dynamic> data = decodedJson["users"] ?? [];

        List<RoleItem> loadedUsers = data.map((json) {
          return RoleItem(
            userId: json['userId'].toString(),
            name: json['name'] ?? "",
            email: json['email'] ?? "",
            phoneNo: json['phoneNumber'] ?? "",
            dateAdded: DateFormat("MM-dd-yyyy HH:mm")
                .format(DateTime.parse(json['registrationDate'])),
            role: json['roleName'] ?? "",
            address: json['address'] ?? "",
          );
        }).toList();

        setState(() {
          _roleList = loadedUsers;
        });

        print("Fetched ${_roleList.length} users");
      } else {
        throw Exception("The API did not return the expected JSON structure.");
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  // Navigation using bottom nav bar.
  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
        break;
      case 1:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Productsscreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
        break;
      case 2:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CategoriesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
        break;
      case 3:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Orders(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
        break;
      case 4:
        // Current screen.
        break;
    }
  }

  // Function to show the Add/Edit User dialog.
  Future<RoleItem?> _showUserDialog({RoleItem? roleToEdit}) async {
    final nameController = TextEditingController(text: roleToEdit?.name ?? "");
    final emailController =
        TextEditingController(text: roleToEdit?.email ?? "");
    final phoneController =
        TextEditingController(text: roleToEdit?.phoneNo ?? "");
    // Add an address controller – used only when the role is Customers.
    final addressController =
        TextEditingController(text: roleToEdit?.address ?? "");

    // For the role dropdown, exclude "All Users".
    String selectedRole = roleToEdit?.role ?? _filters[1]; // default "Admins"
    bool isActive = true; // Not stored in RoleItem; can be used as needed

    return showDialog<RoleItem>(
      context: context,
      builder: (ctx) {
        return Center(
          child: SizedBox(
            width: 550.w,
            child: Dialog(
              backgroundColor: const Color.fromARGB(255, 36, 50, 69),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        roleToEdit == null ? "Add User" : "Edit User",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle:
                              GoogleFonts.spaceGrotesk(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: emailController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle:
                              GoogleFonts.spaceGrotesk(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: phoneController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle:
                              GoogleFonts.spaceGrotesk(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Show the address field only if the selected role is Customers.
                      if (selectedRole.toLowerCase() == "customers")
                        TextField(
                          controller: addressController,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Address",
                            labelStyle:
                                GoogleFonts.spaceGrotesk(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        )
                      else
                        // Optionally, still include the field if you want to allow setting address for other roles.
                        TextField(
                          controller: addressController,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Address (Optional)",
                            labelStyle:
                                GoogleFonts.spaceGrotesk(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      SizedBox(height: 16.h),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: const Color.fromARGB(255, 36, 50, 69),
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Role",
                          labelStyle:
                              GoogleFonts.spaceGrotesk(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        items: _filters
                            .where((role) => role != "All Users")
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16.h),
                      // "Is Active" switch.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Is Active",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white70,
                              fontSize: 16.sp,
                            ),
                          ),
                          CupertinoSwitch(
                            value: isActive,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side:
                                  BorderSide(color: Colors.white54, width: 1.5),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 105, 65, 198),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final newRole = RoleItem(
                                userId: roleToEdit?.userId ??
                                    "new_${DateTime.now().millisecondsSinceEpoch}",
                                name: nameController.text,
                                email: emailController.text,
                                phoneNo: phoneController.text,
                                dateAdded: DateFormat("MM-dd-yyyy HH:mm")
                                    .format(DateTime.now()),
                                role: selectedRole,
                                address:
                                    selectedRole.toLowerCase() == "customers"
                                        ? addressController.text
                                        : addressController.text.isNotEmpty
                                            ? addressController.text
                                            : null,
                              );
                              Navigator.pop(ctx, newRole);
                            },
                            child: Text(
                              roleToEdit == null ? "Add" : "Save",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
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
      },
    );
  }

  // Handler for the Add User button.
  void _handleAddUser() async {
    final newUser = await _showUserDialog();
    if (newUser != null) {
      // Call API to add user.
      final addedUser = await _addUser(newUser);
      if (addedUser != null) {
        setState(() {
          _roleList.add(addedUser);
        });
      }
    }
  }

  // Handler for the Edit action.
  void _handleEditUser(RoleItem role) async {
    final updatedUser = await _showUserDialog(roleToEdit: role);
    if (updatedUser != null) {
      // For editing, update local state.
      setState(() {
        final index = _roleList.indexWhere((r) => r.userId == role.userId);
        if (index != -1) {
          _roleList[index] = updatedUser;
        }
      });
    }
  }

  // API call for adding a user.
  Future<RoleItem?> _addUser(RoleItem newUser) async {
    try {
      final url = Uri.parse(addUserApi);
      // Build the request body. Include the address only if the role is Customers.
      final bodyMap = {
        "name": newUser.name,
        "email": newUser.email,
        "PhoneNumber": newUser.phoneNo,
        "roleName": newUser.role,
        "isActive": "Active",
      };
      if (newUser.role.toLowerCase() == "Customers" &&
          newUser.address != null &&
          newUser.address!.isNotEmpty) {
        bodyMap["address"] = newUser.address!;
      }
      final body = jsonEncode(bodyMap);
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        // Assume the API returns the new user id.
        final newUserId = json["user"]["id"].toString();
        return newUser.copyWith(
          userId: newUserId,
          dateAdded: DateFormat("MM-dd-yyyy HH:mm").format(DateTime.now()),
        );
      } else {
        throw Exception("Failed to add user: ${response.body}");
      }
    } catch (e) {
      print("Error adding user: $e");
      return null;
    }
  }

  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = (_selectedFilterIndex == index);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color.fromARGB(255, 230, 230, 230),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        "*************************************************^^^^*******************************************************Rolemanegment build: _roleList.length = ${_roleList.length}");

    // Change header text based on selected filter.
    String headerText = _selectedFilterIndex == 0
        ? "User Managment"
        : _filters[_selectedFilterIndex];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with dynamic text.
              Row(
                children: [
                  Text(
                    headerText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Search box
                  Container(
                    width: 300.w,
                    height: 55.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120.w,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search ID',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/images/search.svg',
                          width: 20.w,
                          height: 20.h,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 15.w),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 105, 65, 198),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(160.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: _handleAddUser,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/addCat.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Add User',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
              SizedBox(height: 20.h),
              // Filter Chips row.
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 36, 50, 69),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: Row(
                  children: [
                    _buildFilterChip(_filters[0], 0),
                    SizedBox(width: 190.w),
                    _buildFilterChip(_filters[1], 1),
                    SizedBox(width: 195.w),
                    _buildFilterChip(_filters[2], 2),
                    SizedBox(width: 195.w),
                    _buildFilterChip(_filters[3], 3),
                    SizedBox(width: 195.w),
                    _buildFilterChip(_filters[4], 4),
                    SizedBox(width: 190.w),
                    _buildFilterChip(_filters[5], 5),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              RolesTable(
                roles: _roleList,
                filter: _filters[_selectedFilterIndex],
                searchQuery: _searchQuery,
                onDeleteRole: (role) {
                  setState(() {
                    _roleList.removeWhere((r) => r.userId == role.userId);
                  });
                },
                onEditRole: (role) {
                  _handleEditUser(role);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
