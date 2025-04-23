import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesEntry {
  final String positionLabel; // e.g. "1st"
  final String mainName; // e.g. "Yogesh Nivrutti"
  final String subName; // e.g. "Savannah Nguyen"
  final String avatarAsset; // e.g. 'assets/images/avatar.png'
  final String saleAmount; // e.g. "\$19,000"
  final String date; // e.g. "23 Mar 2023"
  final String time; // e.g. "12:34:56 PM"
  SalesEntry({
    required this.positionLabel,
    required this.mainName,
    required this.subName,
    required this.avatarAsset,
    required this.saleAmount,
    required this.date,
    required this.time,
  });
}

/// This widget intercepts and ignores mouse wheel scroll events.
class DisableMouseWheelScroll extends StatelessWidget {
  final Widget child;
  const DisableMouseWheelScroll({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // Ignore wheel scroll events.
        }
      },
      child: child,
    );
  }
}

class SalesTableWidget extends StatefulWidget {
  const SalesTableWidget({Key? key}) : super(key: key);

  @override
  _SalesTableWidgetState createState() => _SalesTableWidgetState();
}

class _SalesTableWidgetState extends State<SalesTableWidget> {
  final ScrollController _scrollController = ScrollController();

  // Sample data (for demonstration)
  final List<SalesEntry> _entries = [
    SalesEntry(
      positionLabel: "10th",
      mainName: "Yogesh Nivrutti",
      subName: "Savannah Nguyen",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$19,000",
      date: "23 Mar 2023",
      time: "12:34:56 PM",
    ),
    SalesEntry(
      positionLabel: "2nd",
      mainName: "Alex Johnson",
      subName: "Michael Brown",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$15,500",
      date: "24 Mar 2023",
      time: "11:22:33 AM",
    ),
    SalesEntry(
      positionLabel: "3rd",
      mainName: "Ideh",
      subName: "Michael Brown",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$15,500",
      date: "24 Mar 2023",
      time: "11:22:33 AM",
    ),
    SalesEntry(
      positionLabel: "4th",
      mainName: "John Doe",
      subName: "Jane Smith",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$10,000",
      date: "25 Mar 2023",
      time: "10:00:00 AM",
    ),
    SalesEntry(
      positionLabel: "5th",
      mainName: "Alice Cooper",
      subName: "Bob Marley",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$12,300",
      date: "26 Mar 2023",
      time: "09:30:00 AM",
    ),
    SalesEntry(
      positionLabel: "1st",
      mainName: "Alice Cooper",
      subName: "Bob Marley",
      avatarAsset: "assets/images/image3.png",
      saleAmount: "\$12,300",
      date: "26 Mar 2023",
      time: "09:30:00 AM",
    ),
    // Add more entries as needed...
  ];

  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Helper: Parse the numeric part of the position string (e.g., "1st" -> 1)
  int parsePosition(String pos) {
    return int.tryParse(pos.replaceAll(RegExp(r'\D'), '')) ?? 0;
  }

  // Helper: Parse the sale amount (e.g., "$19,000" -> 19000)
  int parseSale(String sale) {
    return int.tryParse(sale.replaceAll("\$", "").replaceAll(",", "")) ?? 0;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      List<SalesEntry> sortedEntries = List.from(_entries);

      if (columnIndex == 0) {
        // Sort by Position column.
        sortedEntries.sort(
          (a, b) => parsePosition(a.positionLabel)
              .compareTo(parsePosition(b.positionLabel)),
        );
      } else if (columnIndex == 2) {
        // Sort by Sale Amount column.
        sortedEntries.sort(
          (a, b) => parseSale(a.saleAmount).compareTo(parseSale(b.saleAmount)),
        );
      }
      if (!ascending) {
        sortedEntries = sortedEntries.reversed.toList();
      }
      _entries
        ..clear()
        ..addAll(sortedEntries);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors and styles
    final Color backgroundColor = const Color.fromARGB(0, 0, 0, 0);
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        // Rounded top corners
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      // Wrap the scrollable content in DisableMouseWheelScroll so that wheel events are ignored.
      child: DisableMouseWheelScroll(
        child: SizedBox(
          height: 339.h, // Visible height for approximately 5 rows.
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            // The scroll configuration still allows dragging (press & drag) with the mouse.
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: MaterialStateProperty.all(headingColor),
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
              // Define columns (with sorting enabled on Position and Sale Amount).
              columns: [
                DataColumn(
                  label: Text("Position"),
                  onSort: (columnIndex, ascending) =>
                      _onSort(columnIndex, ascending),
                ),
                DataColumn(label: Text("Name")),
                DataColumn(
                  label: Text("Sale Amount"),
                  onSort: (columnIndex, ascending) =>
                      _onSort(columnIndex, ascending),
                ),
                DataColumn(label: Text("Date & Time")),
              ],
              // Build table rows from entries.
              rows: _entries.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30455C),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          entry.positionLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              entry.avatarAsset,
                              width: 40.w,
                              height: 40.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.mainName,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  entry.subName,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12.sp,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        entry.saleAmount,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.date,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.time,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12.sp,
                              color: Colors.white60,
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
      ),
    );
  }
}
