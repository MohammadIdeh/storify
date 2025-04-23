import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A simple model for each product row.
class Product {
  final int id;
  final String name;
  final String vendor;
  final String price;
  final String stock;
  final String imageAsset; // e.g. 'assets/images/tomatoes.png'

  Product({
    required this.id,
    required this.name,
    required this.vendor,
    required this.price,
    required this.stock,
    required this.imageAsset,
  });
}

class ProductsTable extends StatefulWidget {
  const ProductsTable({Key? key}) : super(key: key);

  @override
  State<ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<ProductsTable> {
  /// Sample data (fake).
  List<Product> _products = [
    Product(
      id: 22739,
      name: "Tomatoes",
      vendor: "Mohammad Ideh",
      price: "\$1,000",
      stock: "62 items",
      imageAsset: "assets/images/image3.png",
    ),
    Product(
      id: 22738,
      name: "Blu 330ml Mojito",
      vendor: "Mohammad Ideh",
      price: "\$900",
      stock: "24 items",
      imageAsset: "assets/images/image3.png",
    ),
    Product(
      id: 22737,
      name: "XL Original 330ml",
      vendor: "Waseem Abed",
      price: "\$750",
      stock: "30 items",
      imageAsset: "assets/images/image3.png",
    ),
    Product(
      id: 22736,
      name: "Coca Cola 1.25L",
      vendor: "Waseem Abed",
      price: "\$1,200",
      stock: "18 items",
      imageAsset: "assets/images/image3.png",
    ),
    Product(
      id: 22735,
      name: "Cabuy Orange 1.5L",
      vendor: "Waseem Abed",
      price: "\$2,000",
      stock: "12 items",
      imageAsset: "assets/images/image3.png",
    ),
    Product(
      id: 22734,
      name: "Coca Cola Zero",
      vendor: "Mohammad Ideh",
      price: "\$3,000",
      stock: "20 items",
      imageAsset: "assets/images/image3.png",
    ),
  ];

  /// DataTable sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  /// Sort logic for each column (optional).
  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      switch (columnIndex) {
        // 0 => Sort by ID Number
        case 0:
          _products.sort((a, b) => a.id.compareTo(b.id));
          break;
        // 1 => Sort by Name
        case 1:
          _products.sort((a, b) => a.name.compareTo(b.name));
          break;
        // 2 => Sort by Vendor
        case 2:
          _products.sort((a, b) => a.vendor.compareTo(b.vendor));
          break;
        // 3 => Sort by Price (parsing numeric value)
        case 3:
          int parsePrice(String price) {
            return int.tryParse(
                  price.replaceAll("\$", "").replaceAll(",", ""),
                ) ??
                0;
          }
          _products.sort(
            (a, b) => parsePrice(a.price).compareTo(parsePrice(b.price)),
          );
          break;
        // 4 => Sort by Stock (parsing numeric value)
        case 4:
          int parseStock(String stock) {
            return int.tryParse(stock.replaceAll(" items", "")) ?? 0;
          }
          _products.sort(
            (a, b) => parseStock(a.stock).compareTo(parseStock(b.stock)),
          );
          break;
      }

      // Reverse list if descending is selected.
      if (!ascending) {
        _products = _products.reversed.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Main container background
    final Color backgroundColor = const Color.fromARGB(0, 0, 0, 0);
    // Heading row color
    final Color headingColor = const Color.fromARGB(255, 36, 50, 69);
    // Divider and border color/thickness
    final BorderSide dividerSide =
        BorderSide(color: const Color.fromARGB(255, 34, 53, 62), width: 1);
    final BorderSide dividerSide2 =
        BorderSide(color: const Color.fromARGB(255, 36, 50, 69), width: 2);
    return Container(
      width: double.infinity,
      clipBehavior:
          Clip.antiAlias, // Ensures rounded corners clip child content
      decoration: BoxDecoration(
        color: backgroundColor,
        // Rounded top corners
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: DataTable(
        // Hide built-in sort arrow by making it transparent.

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
        dividerThickness: 0, // Using custom TableBorder for dividers
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.8),
          fontSize: 13.sp,
        ),
        // Define columns (first/last columns removed)
        columns: [
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: _buildColumnHeader("ID Number"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: _buildColumnHeader("Name"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: _buildColumnHeader("Vendor"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: _buildColumnHeader("Price"),
          ),
          DataColumn(
            onSort: (colIndex, asc) => _onSort(colIndex, asc),
            label: _buildColumnHeader("Stock"),
          ),
        ],
        // Build table rows.
        rows: _products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text("${product.id}")),
              DataCell(Row(
                children: [
                  Image.asset(
                    product.imageAsset,
                    width: 30.w,
                    height: 30.h,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(product.name)),
                ],
              )),
              DataCell(Text(product.vendor)),
              DataCell(Text(product.price)),
              DataCell(Text(product.stock)),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Builds a header widget with custom up/down arrows placed closer together.
  Widget _buildColumnHeader(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
      ],
    );
  }
}
