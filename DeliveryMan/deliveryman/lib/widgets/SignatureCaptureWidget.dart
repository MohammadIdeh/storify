import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

class SignatureCaptureWidget extends StatefulWidget {
  final Function(Uint8List) onSignatureConfirmed;
  final VoidCallback onCancel;

  const SignatureCaptureWidget({
    Key? key,
    required this.onSignatureConfirmed,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SignatureCaptureWidget> createState() => _SignatureCaptureWidgetState();
}

class _SignatureCaptureWidgetState extends State<SignatureCaptureWidget> {
  final GlobalKey _signatureKey = GlobalKey();
  final List<Offset?> _points = <Offset?>[];
  bool _hasSignature = false;

  void _addPoint(Offset point) {
    setState(() {
      _points.add(point);
      _hasSignature = true;
    });
  }

  void _addEndPoint() {
    setState(() {
      _points.add(null);
    });
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
  }

  Future<void> _confirmSignature() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide a signature first',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Capture the signature as an image
      RenderRepaintBoundary boundary = _signatureKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        widget.onSignatureConfirmed(pngBytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error capturing signature: $e',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF304050),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6941C6).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF6941C6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Customer Signature',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Please ask the customer to sign below to confirm delivery',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: const Color(0xAAFFFFFF),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Signature Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: RepaintBoundary(
                  key: _signatureKey,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        Offset localPosition =
                            renderBox.globalToLocal(details.globalPosition);
                        _addPoint(localPosition);
                      },
                      onPanEnd: (details) => _addEndPoint(),
                      child: CustomPaint(
                        painter: SignaturePainter(_points),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom hint
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xFF6941C6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Touch and drag to sign',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF6941C6),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Clear button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _clearSignature,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D2939),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmSignature,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Confirm Signature',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
