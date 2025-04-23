import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FiltersPanel extends StatefulWidget {
  const FiltersPanel({Key? key}) : super(key: key);

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  DateTime? _pickedDate;

  // checkbox states
  bool _locLorem = false, _locIpsum = false;
  bool _shipAll = true, _shipDelivery = false, _shipDone = false;
  bool _payAll = true,
      _payDone = false,
      _payCancelled = false,
      _payPending = false,
      _payDelayed = false;
  bool _typeAll = true,
      _type1 = false,
      _type2 = false,
      _type3 = false,
      _type4 = false,
      _type5 = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _pickedDate = d);
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
        ),
        Text(label,
            style:
                GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14.sp)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500.w,
      height: 820, // Adjust height as needed
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),

          // Price Range
          Text('Price range',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPrice,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Min price',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2E3954),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: _maxPrice,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Max price',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2E3954),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Location Type
          Text('Location Type',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(spacing: 10, children: [
            _buildCheckbox(
                'Lorem', _locLorem, (v) => setState(() => _locLorem = v!)),
            _buildCheckbox(
                'Ipsum', _locIpsum, (v) => setState(() => _locIpsum = v!)),
          ]),
          SizedBox(height: 20.h),

          // Shipping Status
          Text('Shipping Status',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(spacing: 10, children: [
            _buildCheckbox(
                'All Status', _shipAll, (v) => setState(() => _shipAll = v!)),
            _buildCheckbox('Delivery', _shipDelivery,
                (v) => setState(() => _shipDelivery = v!)),
            _buildCheckbox(
                'Done', _shipDone, (v) => setState(() => _shipDone = v!)),
          ]),
          SizedBox(height: 20.h),

          // Date Picker
          Text('Date',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFF2E3954),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _pickedDate == null
                    ? 'Pick Date'
                    : '${_pickedDate!.year}-${_pickedDate!.month.toString().padLeft(2, '0')}-${_pickedDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: _pickedDate == null ? Colors.white54 : Colors.white),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Shipment type
          Text('Shipment type',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(spacing: 10, children: [
            _buildCheckbox(
                'All type', _typeAll, (v) => setState(() => _typeAll = v!)),
            _buildCheckbox(
                'Type 1', _type1, (v) => setState(() => _type1 = v!)),
            _buildCheckbox(
                'Type 2', _type2, (v) => setState(() => _type2 = v!)),
            _buildCheckbox(
                'Type 3', _type3, (v) => setState(() => _type3 = v!)),
            _buildCheckbox(
                'Type 4', _type4, (v) => setState(() => _type4 = v!)),
            _buildCheckbox(
                'Type 5', _type5, (v) => setState(() => _type5 = v!)),
          ]),
          SizedBox(height: 20.h),

          // Payment Status
          Text('Payment Status',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(spacing: 10, children: [
            _buildCheckbox(
                'All Status', _payAll, (v) => setState(() => _payAll = v!)),
            _buildCheckbox(
                'Done', _payDone, (v) => setState(() => _payDone = v!)),
            _buildCheckbox('Cancelled', _payCancelled,
                (v) => setState(() => _payCancelled = v!)),
            _buildCheckbox('Pending', _payPending,
                (v) => setState(() => _payPending = v!)),
            _buildCheckbox('Delayed', _payDelayed,
                (v) => setState(() => _payDelayed = v!)),
          ]),
          SizedBox(height: 24.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text('Cancel',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Save Filter',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
