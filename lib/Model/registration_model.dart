class RegistrationAuthModel {
  bool? isSuccess;
  String? message;
  Data? data;

  RegistrationAuthModel({this.isSuccess, this.message, this.data});

  RegistrationAuthModel.fromJson(Map<String, dynamic> json) {
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isSuccess'] = this.isSuccess;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? userId;
  String? message;

  Data({this.userId, this.message});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['message'] = this.message;
    return data;
  }
}
