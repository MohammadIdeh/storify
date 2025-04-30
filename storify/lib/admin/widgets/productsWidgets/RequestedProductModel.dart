import 'package:flutter/material.dart';

class RequestedProductModel {
  final int id;
  final String name;
  final double costPrice;
  final double sellPrice;
  final int categoryId;
  final int supplierId;
  final String status;
  final String barcode;
  final String? warranty;
  final DateTime? prodDate;
  final DateTime? expDate;
  final String? description;
  final String? adminNote;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryInfo category;
  final SupplierInfo supplier;

  RequestedProductModel({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.categoryId,
    required this.supplierId,
    required this.status,
    required this.barcode,
    this.warranty,
    this.prodDate,
    this.expDate,
    this.description,
    this.adminNote,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.supplier,
  });

  factory RequestedProductModel.fromJson(Map<String, dynamic> json) {
    return RequestedProductModel(
      id: json['id'],
      name: json['name'],
      costPrice: double.parse(json['costPrice']),
      sellPrice: double.parse(json['sellPrice']),
      categoryId: json['categoryId'],
      supplierId: json['supplierId'],
      status: json['status'],
      barcode: json['barcode'],
      warranty: json['warranty'],
      prodDate:
          json['prodDate'] != null ? DateTime.parse(json['prodDate']) : null,
      expDate: json['expDate'] != null ? DateTime.parse(json['expDate']) : null,
      description: json['description'],
      adminNote: json['adminNote'],
      image: json['image'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      category: CategoryInfo.fromJson(json['category']),
      supplier: SupplierInfo.fromJson(json['supplier']),
    );
  }

  // Create a copy of the model with updated values
  RequestedProductModel copyWith({
    int? id,
    String? name,
    double? costPrice,
    double? sellPrice,
    int? categoryId,
    int? supplierId,
    String? status,
    String? barcode,
    String? warranty,
    DateTime? prodDate,
    DateTime? expDate,
    String? description,
    String? adminNote,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryInfo? category,
    SupplierInfo? supplier,
  }) {
    return RequestedProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      warranty: warranty ?? this.warranty,
      prodDate: prodDate ?? this.prodDate,
      expDate: expDate ?? this.expDate,
      description: description ?? this.description,
      adminNote: adminNote ?? this.adminNote,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
    );
  }
}

class CategoryInfo {
  final int categoryID;
  final String categoryName;

  CategoryInfo({
    required this.categoryID,
    required this.categoryName,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      categoryID: json['categoryID'],
      categoryName: json['categoryName'],
    );
  }
}

class SupplierInfo {
  final int id;
  final int userId;
  final String accountBalance;
  final UserInfo user;

  SupplierInfo({
    required this.id,
    required this.userId,
    required this.accountBalance,
    required this.user,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'],
      userId: json['userId'],
      accountBalance: json['accountBalance'],
      user: UserInfo.fromJson(json['user']),
    );
  }
}

class UserInfo {
  final int userId;
  final String name;
  final String email;

  UserInfo({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
    );
  }
}
