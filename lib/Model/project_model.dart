class ProjectModel {
  bool? isSuccess;
  String? message;
  List<DataProject>? data;

  ProjectModel({this.isSuccess, this.message, this.data});

  ProjectModel.fromJson(Map<String, dynamic> json) {
    isSuccess = json['isSuccess'];
    message = json['message'];
    if (json['data'] != null) {
      data = <DataProject>[];
      json['data'].forEach((v) {
        data!.add(new DataProject.fromJson(v));
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

class DataProject {
  int? projectId;
  String? projectName;

  DataProject({this.projectId, this.projectName});

  DataProject.fromJson(Map<String, dynamic> json) {
    projectId = json['projectId'];
    projectName = json['projectName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['projectId'] = this.projectId;
    data['projectName'] = this.projectName;
    return data;
  }
}
