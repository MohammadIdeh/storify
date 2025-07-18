import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart'; // for SVG assets
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class AddCategoryPanel extends StatefulWidget {
  final void Function(
          String categoryName, bool isActive, String image, String description)?
      onPublish;
  final VoidCallback? onCancel;

  const AddCategoryPanel({super.key, this.onPublish, this.onCancel});

  @override
  State<AddCategoryPanel> createState() => _AddCategoryPanelState();
}

class _AddCategoryPanelState extends State<AddCategoryPanel> {
  String _categoryName = "";
  bool _isActive = true;
  String _description = "";
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  // Image state
  String? _image; // null when no image is selected
  String? _base64Image; // To store base64 encoded image for API

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final html.File file = files.first;

        // Check file size - 5MB limit from backend validation
        final fileSize = file.size;
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = l10n.imageSizeExceedsLimit;
          });
          debugPrint(
              "File too large: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB (max 5MB)");
          return;
        }

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          try {
            final dataUrl = reader.result as String;
            setState(() {
              _image = dataUrl;

              // Extract base64 data - handle both format variations
              final String base64Data =
                  dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;

              _base64Image = base64Data;

              // Clear any previous error messages
              _errorMessage = null;
            });

            // Log the file size for debugging
            final decodedImageBytes = base64Decode(_base64Image!).length;
            debugPrint(
                "Image loaded: ${(decodedImageBytes / (1024 * 1024)).toStringAsFixed(2)}MB of 5MB limit");
          } catch (e) {
            setState(() {
              _errorMessage = "${l10n.errorProcessingImage}: $e";
            });
            debugPrint("Error processing image: $e");
          }
        });
      }
    });
  }

  bool get _isFormValid {
    return _categoryName.trim().isNotEmpty && _image != null;
  }

  Future<void> _submitCategory() async {
    if (!_isFormValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _retryCount = 0;
    });

    await _attemptSubmit();
  }

  Future<void> _attemptSubmit() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    try {
      // Check image size again before submission
      if (_base64Image != null) {
        final decodedImageBytes = base64Decode(_base64Image!).length;
        if (decodedImageBytes > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = l10n.imageSizeExceedsLimit;
            _isSubmitting = false;
          });
          return;
        }
      }

      // Get auth token (not headers)
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = l10n.authenticationRequired;
          _isSubmitting = false;
        });
        return;
      }

      debugPrint('Creating multipart request...');

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://finalproject-a5ls.onrender.com/category/add'),
      );

      // Add token header (notice it's 'token', not 'Authorization')
      request.headers['token'] = token;

      // Add form fields
      request.fields['categoryName'] = _categoryName.trim();
      request.fields['status'] = _isActive ? 'Active' : 'NotActive';

      // Add description if not empty
      if (_description.trim().isNotEmpty) {
        request.fields['description'] = _description.trim();
      }

      // Add image as file
      if (_base64Image != null) {
        // Convert base64 back to bytes
        final imageBytes = base64Decode(_base64Image!);

        // Create a MultipartFile from the bytes
        final imageFile = http.MultipartFile.fromBytes(
          'image', // Field name must be 'image'
          imageBytes,
          filename: 'category_image.jpg', // Provide a filename
          contentType: MediaType('image', 'jpeg'), // Specify content type
        );

        // Add the file to the request
        request.files.add(imageFile);
      }

      debugPrint(
          'Sending multipart request with token: ${token.substring(0, 20)}...');

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(l10n.requestTimedOut);
        },
      );

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('API response received: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Process the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response data
        final responseData = json.decode(response.body);
        debugPrint('Success response: $responseData');

        // Success case
        if (widget.onPublish != null) {
          widget.onPublish!(
            _categoryName.trim(),
            _isActive,
            _image!,
            _description.trim(),
          );
        }
      } else {
        // Handle error...
        String errorMsg =
            '${l10n.failedToAddCategory}: ${l10n.status} ${response.statusCode}';

        try {
          final responseData = json.decode(response.body);
          if (responseData.containsKey('message')) {
            errorMsg = responseData['message'];
          }
          debugPrint('Error response: $responseData');
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }

        setState(() {
          _errorMessage = errorMsg;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      // Retry logic...
      if (_retryCount < _maxRetries) {
        _retryCount++;
        setState(() {
          _errorMessage =
              '${l10n.networkIssueRetrying} (${l10n.attempt} $_retryCount ${l10n.offf} $_maxRetries)';
        });

        // Wait before retrying
        await Future.delayed(Duration(seconds: 2));
        return _attemptSubmit();
      } else {
        setState(() {
          _errorMessage =
              '${l10n.networkError}: $e\n\n${l10n.checkInternetConnection}';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Fixed container for upload image.
            Container(
              margin: EdgeInsets.symmetric(vertical: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 36, 50, 69),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 700,
                    height: 500.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 28, 36, 46),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: InkWell(
                      onTap: _isSubmitting ? null : _pickImage,
                      child: _image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/gallery.svg',
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  l10n.clickToUploadImage,
                                  textAlign: TextAlign.center,
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
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                _image!,
                                width: 700,
                                height: 500.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  if (_isSubmitting)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: const Color.fromARGB(255, 105, 65, 198),
                              ),
                              if (_retryCount > 0) ...[
                                SizedBox(height: 16.h),
                                Text(
                                  "${l10n.retrying} (${l10n.attempt} $_retryCount ${l10n.offf} $_maxRetries)",
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
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 100.w),
            // Right side: Expanded container that takes remaining width.
            Expanded(
              child: Container(
                height: 545.h,
                margin: EdgeInsets.symmetric(vertical: 16.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 36, 50, 69),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show error message if there is one
                    if (_errorMessage != null) ...[
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: isArabic
                                        ? GoogleFonts.cairo(
                                            color: Colors.red,
                                            fontSize: 14.sp,
                                          )
                                        : GoogleFonts.spaceGrotesk(
                                            color: Colors.red,
                                            fontSize: 14.sp,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage!.contains(l10n.networkError) &&
                                !_isSubmitting) ...[
                              SizedBox(height: 8.h),
                              TextButton(
                                onPressed: _submitCategory,
                                child: Text(
                                  l10n.tryAgain,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    Text(
                      "${l10n.categoryName} *",
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _categoryName = value;
                        });
                      },
                      enabled: !_isSubmitting,
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: isArabic
                          ? GoogleFonts.cairo(color: Colors.white)
                          : GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 68, 88),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        hintText: l10n.enterCategoryName,
                        hintStyle: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              ),
                        errorStyle: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.red,
                                fontSize: 12.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.categoryNameRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.description,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _description = value;
                        });
                      },
                      enabled: !_isSubmitting,
                      maxLines: 3,
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: isArabic
                          ? GoogleFonts.cairo(color: Colors.white)
                          : GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(255, 54, 68, 88),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        hintText: l10n.enterDescriptionOptional,
                        hintStyle: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.availability,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  setState(() {
                                    _isActive = val;
                                  });
                                },
                          activeColor: const Color.fromARGB(255, 105, 65, 198),
                        ),
                        Text(
                          _isActive ? l10n.active : l10n.notActive,
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
                      ],
                    ),
                    if (_image == null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        l10n.pleaseUploadImage,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                color: Colors.red,
                                fontSize: 12.sp,
                              )
                            : GoogleFonts.spaceGrotesk(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                      ),
                    ],
                    SizedBox(height: 50.h),
                    // Bottom Row: Cancel and Publish Category.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 20.h),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 105, 123, 123),
                                width: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : widget.onCancel,
                          child: Text(
                            l10n.cancel,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isSubmitting
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isSubmitting
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white,
                                  ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid && !_isSubmitting
                                ? const Color.fromARGB(255, 105, 65, 198)
                                : Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 25.h),
                          ),
                          onPressed: (_isFormValid && !_isSubmitting)
                              ? _submitCategory
                              : null,
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.publishCategory,
                                  style: isArabic
                                      ? GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                        ),
                      ],
                    )
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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
