class LoginAuthModel {
  bool? isSuccess;
  String? message;
  Data? data;

  LoginAuthModel({this.isSuccess, this.message, this.data});

  LoginAuthModel.fromJson(Map<String, dynamic> json) {
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
  String? userId;
  String? uId;
  String? roleFlag;
  String? roleName;
  String? fname;
  String? accessToken;
  String? expiresAt;

  Data({
    this.userId,
    this.uId,
    this.roleFlag,
    this.roleName,
    this.fname,
    this.accessToken,
    this.expiresAt
  });

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    uId = json['uId'];
    roleFlag = json['roleFlag'];
    roleName = json['roleName'];
    fname = json['fname'];
    accessToken = json['accessToken'];
    expiresAt = json['expiresAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['userId'] = this.userId;
    data['uId'] = this.uId;
    data['roleFlag'] = this.roleFlag;
    data['roleName'] = this.roleName;
    data['fname'] = this.fname;
    data['accessToken'] = this.accessToken;
    data['expiresAt'] = this.expiresAt;
    return data;
  }
}
