class LoginAuthModel {
  bool? isSuccess;
  String? message;
  Data? data;

  LoginAuthModel({this.isSuccess, this.message, this.data});

  LoginAuthModel.fromJson(Map<String, dynamic> json) {
    isSuccess = json['isSuccess'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    // If data contains a specific error message, prioritize it when top-level message is generic or empty
    if (data?.message != null && data!.message!.trim().isNotEmpty) {
      if (message == null || message == 'error' || message!.trim().isEmpty) {
        message = data!.message!.trim();
      }
    }
  }

  String get displayMessage {
    if (data?.message != null && data!.message!.trim().isNotEmpty) {
      return data!.message!.trim();
    }
    if (message != null && message!.trim().isNotEmpty && message != 'error') {
      return message!.trim();
    }
    return message ?? '';
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

class Data {
  String? userId;
  String? uId;
  String? roleFlag;
  String? roleName;
  String? fname;
  String? accessToken;
  String? expiresAt;
  String? message;

  Data({
    this.userId,
    this.uId,
    this.roleFlag,
    this.roleName,
    this.fname,
    this.accessToken,
    this.expiresAt,
    this.message,
  });

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    uId = json['uId']?.toString();
    roleFlag = json['roleFlag']?.toString();
    roleName = json['roleName']?.toString();
    fname = json['fname']?.toString();
    accessToken = json['accessToken']?.toString();
    expiresAt = json['expiresAt']?.toString();
    message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['userId'] = userId;
    data['uId'] = uId;
    data['roleFlag'] = roleFlag;
    data['roleName'] = roleName;
    data['fname'] = fname;
    data['accessToken'] = accessToken;
    data['expiresAt'] = expiresAt;
    data['message'] = message;
    return data;
  }
}

