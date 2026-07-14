class ExecutionDashboardSummaryDetailsModel {
  bool? isSuccess;
  String? message;
  List<DataDashboard>? data;

  ExecutionDashboardSummaryDetailsModel(
      {this.isSuccess, this.message, this.data});

  ExecutionDashboardSummaryDetailsModel.fromJson(Map<String, dynamic> json) {
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      data = <DataDashboard>[];
      json['data'].forEach((v) {
        data!.add(new DataDashboard.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DataDashboard {
  dynamic printName;
  dynamic status;
  dynamic remarks;
  dynamic canId;

  DataDashboard({this.printName, this.status, this.remarks, this.canId});

  DataDashboard.fromJson(Map<String, dynamic> json) {
    printName = json['printName'];
    status = json['status'];
    remarks = json['remarks'];
    canId = json['canid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['printName'] = this.printName;
    data['status'] = this.status;
    data['remarks'] = this.remarks;
    data['canid'] = this.canId;
    return data;
  }
}
