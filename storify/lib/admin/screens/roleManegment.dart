import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/widgets/rolesWidgets/role_item.dart';
import 'package:storify/admin/widgets/rolesWidgets/rolesTable.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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
  final List<String> _filters = [
    "All Users",
    "Admin",
    "Employee",
    "Customer",
    "Supplier",
    "Delivery Employee"
  ];

  // This list will be populated from the API.
  List<RoleItem> _roleList = [];
  // API endpoints.
  // Make sure your API returns the fields exactly as needed for the table.
  final String getUsersApi =
      "https://finalproject-a5ls.onrender.com/auth/users";
  final String addUserApi =
      "https://finalproject-a5ls.onrender.com/auth/register";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<RoleItem?> _updateUser(RoleItem updatedUser) async {
    try {
      final url = Uri.parse(
          "https://finalproject-a5ls.onrender.com/auth/${updatedUser.userId}");
      final bodyMap = {
        "name": updatedUser.name,
        "email": updatedUser.email,
        "phoneNumber": updatedUser.phoneNo,
        "roleName": updatedUser.role,
        // Send the active value as "1" or "0"
        "isActive": updatedUser.isActive ? "1" : "0",
      };

      if (updatedUser.role.toLowerCase() == "customer" &&
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
        jsonDecode(response.body);
        // Optionally update dateAdded if needed.
        return updatedUser.copyWith(
          dateAdded: DateFormat("MM-dd-yyyy HH:mm").format(DateTime.now()),
        );
      } else {
        throw Exception("Failed to update user: ${response.body}");
      }
    } catch (e) {
      print("Error updating user: $e");
      return null;
    }
  }

  Future<bool> _deleteUser(String userId) async {
    try {
      final url =
          Uri.parse("https://finalproject-a5ls.onrender.com/auth/$userId");
      final response = await http.delete(url, headers: {
        "Content-Type": "application/json",
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse(getUsersApi),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final decodedJson = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey("users")) {
        data = decodedJson["users"] ?? [];
      } else if (decodedJson is List) {
        data = decodedJson;
      } else {
        throw Exception("The API did not return the expected JSON structure.");
      }
      List<RoleItem> loadedUsers = data.map((json) {
        return RoleItem(
          userId: json['userId'].toString(),
          name: json['name'] ?? "",
          email: json['email'] ?? "",
          phoneNo: json['phoneNumber'] ?? "",
          dateAdded: DateFormat("MM-dd-yyyy HH:mm")
              .format(DateTime.parse(json['registrationDate'])),
          role: json['roleName'] ?? "",
          isActive: parseIsActive(json['isActive']),
          address: json['address'] ?? "",
        );
      }).toList();

      setState(() {
        _roleList = loadedUsers;
      });

      print("Fetched ${_roleList.length} users");
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
      case 5:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Track(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
        break;
    }
  }

  // Function to show the Add/Edit User dialog.
  Future<RoleItem?> _showUserDialog({RoleItem? roleToEdit}) async {
    // Initialize controllers with roleToEdit's data if editing
    final nameController = TextEditingController(text: roleToEdit?.name ?? "");
    final emailController =
        TextEditingController(text: roleToEdit?.email ?? "");
    final phoneController =
        TextEditingController(text: roleToEdit?.phoneNo ?? "");
    final addressController =
        TextEditingController(text: roleToEdit?.address ?? "");

    // For the role dropdown, exclude "All Users".
    String selectedRole = roleToEdit?.role ?? _filters[1]; // default "Admin"
    // Use a local variable for isActive.
    bool localIsActive = roleToEdit?.isActive ?? true;

    return showDialog<RoleItem>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
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
                        // Display address field based on selectedRole.
                        if (selectedRole.toLowerCase() == "customer")
                          TextField(
                            controller: addressController,
                            style:
                                GoogleFonts.spaceGrotesk(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Address",
                              labelStyle: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          )
                        else
                          TextField(
                            controller: addressController,
                            style:
                                GoogleFonts.spaceGrotesk(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Address (Optional)",
                              labelStyle: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70),
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
                              setStateDialog(() {
                                selectedRole = val;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16.h),
                        // "Is Active" switch using the dialog local state.
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
                              value: localIsActive,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setStateDialog(() {
                                  localIsActive = value;
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
                                side: BorderSide(
                                    color: Colors.white54, width: 1.5),
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
                                // Validate that all required fields are filled.
                                if (nameController.text.trim().isEmpty ||
                                    phoneController.text.trim().isEmpty ||
                                    selectedRole.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please fill all required fields",
                                        style: GoogleFonts.spaceGrotesk(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                // Create the new RoleItem object and use localIsActive
                                final newRole = RoleItem(
                                  userId: roleToEdit?.userId ??
                                      "new_${DateTime.now().millisecondsSinceEpoch}",
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phoneNo: phoneController.text.trim(),
                                  dateAdded: DateFormat("MM-dd-yyyy HH:mm")
                                      .format(DateTime.now()),
                                  role: selectedRole,
                                  address:
                                      selectedRole.toLowerCase() == "customer"
                                          ? addressController.text.trim()
                                          : (addressController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? addressController.text.trim()
                                              : null),
                                  isActive: localIsActive,
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
        });
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

  void _handleEditUser(RoleItem role) async {
    final updatedUser = await _showUserDialog(roleToEdit: role);
    if (updatedUser != null) {
      final resultUser = await _updateUser(updatedUser);
      if (resultUser != null) {
        setState(() {
          final index = _roleList.indexWhere((r) => r.userId == role.userId);
          if (index != -1) {
            _roleList[index] = resultUser;
            // Also update the switch state mapping.
            // For example, if _switchStates is defined in the RolesTable and provided from parent
            // You might want to update that list as well if necessary.
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update user",
                style: GoogleFonts.spaceGrotesk()),
          ),
        );
      }
    }
  }

  // API call for adding a user.
  Future<RoleItem?> _addUser(RoleItem newUser) async {
    try {
      final url = Uri.parse(addUserApi);
      // Build the request body using the correct keys and value types.
      final bodyMap = {
        "name": newUser.name,
        "email": newUser.email,
        "phoneNumber": newUser.phoneNo, // lowercase key
        "roleName": newUser.role,
        // Send "1" if true, "0" otherwise.
        "isActive": newUser.isActive ? "1" : "0",
      };

      if (newUser.role.toLowerCase() == "customer" &&
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
          profilePictureUrl:
              profilePictureUrl, // Pass the profile picture URL here
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
                      fontSize: 35.sp,
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
                // Pass the parent's _deleteUser method as a callback.
                onDeleteUser: _deleteUser,
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

// Helper function to parse isActive value.
bool parseIsActive(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value == "1";
  }
  return false;
}
