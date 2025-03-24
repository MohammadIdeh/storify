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

/// The widget that shows a sortable table of products.
class ProductsTable extends StatefulWidget {
  const ProductsTable({super.key});

  @override
  State<ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<ProductsTable> {
  /// Sample data (fake).
  /// Replace `imageAsset` with your actual product PNG paths.
  List<Product> _products = [
    Product(
      id: 22739,
      name: "Tomatoes",
      vendor: "Mohammad Ideh",
      price: "\$1,000",
      stock: "62 items",
      imageAsset: "assets/images/tomatoes.png",
    ),
    Product(
      id: 22738,
      name: "Blu 330ml Mojito",
      vendor: "Mohammad Ideh",
      price: "\$900",
      stock: "24 items",
      imageAsset: "assets/images/blu.png",
    ),
    Product(
      id: 22737,
      name: "XL Original 330ml",
      vendor: "Waseem Abed",
      price: "\$750",
      stock: "30 items",
      imageAsset: "assets/images/xl.png",
    ),
    Product(
      id: 22736,
      name: "Coca Cola 1.25L",
      vendor: "Waseem Abed",
      price: "\$1,200",
      stock: "18 items",
      imageAsset: "assets/images/cocacola.png",
    ),
    Product(
      id: 22735,
      name: "Cabuy Orange 1.5L",
      vendor: "Waseem Abed",
      price: "\$2,000",
      stock: "12 items",
      imageAsset: "assets/images/cabuy.png",
    ),
    Product(
      id: 22734,
      name: "Coca Cola Zero",
      vendor: "Mohammad Ideh",
      price: "\$3,000",
      stock: "20 items",
      imageAsset: "assets/images/cola_zero.png",
    ),
  ];

  /// DataTable sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  /// Sort logic for each column
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
        // 3 => Sort by Price (string => parse int if you want numeric)
        case 3:
          // We'll do a naive parse ignoring the '$' and commas
          int parsePrice(String price) {
            // e.g. "$1,000" => "1000"
            return int.tryParse(
                  price.replaceAll("\$", "").replaceAll(",", ""),
                ) ??
                0;
          }

          _products.sort(
              (a, b) => parsePrice(a.price).compareTo(parsePrice(b.price)));
          break;
        // 4 => Sort by Stock (string => parse int if you want numeric)
        case 4:
          int parseStock(String stock) {
            // e.g. "62 items" => "62"
            return int.tryParse(stock.replaceAll(" items", "")) ?? 0;
          }

          _products.sort(
              (a, b) => parseStock(a.stock).compareTo(parseStock(b.stock)));
          break;
      }

      // If descending, reverse after sort
      if (!ascending) {
        _products = _products.reversed.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Main container background from your screenshot (#2D3C4E)
    final Color backgroundColor = const Color(0xFF2D3C4E);

    return Container(
      width: double.infinity,
      // A padding around the table
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      // Horizontal scroll if columns overflow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Let the DataTable handle showing the arrow icons
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,

          // Some style customizations
          columnSpacing: 30.w,
          headingRowColor: MaterialStateProperty.all(backgroundColor),
          dataRowColor: MaterialStateProperty.all(backgroundColor),
          dividerThickness: 0.5,
          headingTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),

          columns: [
            // ID Number
            DataColumn(
              label: Text("ID Number"),
              onSort: _onSort,
            ),
            // Name (with image)
            DataColumn(
              label: Text("Name"),
              onSort: _onSort,
            ),
            // Vendor
            DataColumn(
              label: Text("Vendor"),
              onSort: _onSort,
            ),
            // Price
            DataColumn(
              label: Text("Price"),
              onSort: _onSort,
            ),
            // Stock
            DataColumn(
              label: Text("Stock"),
              onSort: _onSort,
            ),
          ],

          rows: _products.map((product) {
            return DataRow(
              cells: [
                // ID Number
                DataCell(Text("${product.id}")),
                // Name + image
                DataCell(Row(
                  children: [
                    // Product image
                    Image.asset(
                      product.imageAsset,
                      width: 30.w,
                      height: 30.h,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(product.name),
                    ),
                  ],
                )),
                // Vendor
                DataCell(Text(product.vendor)),
                // Price
                DataCell(Text(product.price)),
                // Stock
                DataCell(Text(product.stock)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
