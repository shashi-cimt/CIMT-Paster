class ExecutionDashboardSummaryModel {
  bool? isSuccess;
  String? message;
  DashboardData? data;

  ExecutionDashboardSummaryModel({
    this.isSuccess,
    this.message,
    this.data,
  });

  ExecutionDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? DashboardData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isSuccess'] = isSuccess;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class DashboardData {
  int? totalPrints;
  int? printsUploaded;
  int? executedByVendorRaw;
  int? approved;
  int? partial;
  int? rejected;

  DashboardData({
    this.totalPrints,
    this.printsUploaded,
    this.executedByVendorRaw,
    this.approved,
    this.partial,
    this.rejected,
  });

  DashboardData.fromJson(Map<String, dynamic> json) {
    // Handle both int and String types safely
    totalPrints = _parseToInt(json['totalPrints']);
    printsUploaded = _parseToInt(json['printsUploaded']);
    executedByVendorRaw = _parseToInt(json['executedByVendorRaw']);
    approved = _parseToInt(json['approved']);
    partial = _parseToInt(json['partial']);
    rejected = _parseToInt(json['rejected']);
  }

  // Helper method to safely parse values to int
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalPrints'] = totalPrints;
    data['printsUploaded'] = printsUploaded;
    data['executedByVendorRaw'] = executedByVendorRaw;
    data['approved'] = approved;
    data['partial'] = partial;
    data['rejected'] = rejected;
    return data;
  }
}