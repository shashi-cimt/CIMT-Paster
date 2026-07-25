class SeePlanModel {
  int? status;
  String? message;
  List<Data>? data;

  SeePlanModel({
    this.status,
    this.message,
    this.data,
  });

  SeePlanModel.fromJson(Map<String, dynamic> json) {
    status = json['Status'];
    message = json['Message'];

    if (json['Data'] != null) {
      data = <Data>[];
      json['Data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "Status": status,
      "Message": message,
      "Data": data?.map((e) => e.toJson()).toList(),
    };
  }
}

class Data {
  int? planServerId;
  String? planCode;
  String? villageCode;
  String? villageName;
  String? tehsil;
  String? stateName;
  String? districtName;
  String? latitude;
  String? longitude;
  String? projectName;
  String? projectId;
  int? noOfPrints;
  int? noOfBalance;
  String? range;
  int? artworkId;
  String? artworkName;
  String? height;
  String? width;
  String? sqft;
  String? artworkUrl;

  // NEW
  List<LocationData>? locations;

  Data({
    this.planServerId,
    this.planCode,
    this.villageCode,
    this.villageName,
    this.tehsil,
    this.stateName,
    this.districtName,
    this.latitude,
    this.longitude,
    this.projectName,
    this.projectId,
    this.noOfPrints,
    this.noOfBalance,
    this.range,
    this.artworkId,
    this.artworkName,
    this.height,
    this.width,
    this.sqft,
    this.artworkUrl,
    this.locations,
  });

  Data.fromJson(Map<String, dynamic> json) {
    planServerId = json['planServerId'];
    planCode = json['planCode'];
    villageCode = json['villageCode'];
    villageName = json['villageName'];
    tehsil = json['tehsil'];
    stateName = json['stateName'];
    districtName = json['districtName'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    projectName = json['projectName'];
    projectId = json['projectId'];
    noOfPrints = json['noOfPrints'];
    noOfBalance = json['noOfBalance'];
    range = json['range'];
    artworkId = json['artworkId'];
    artworkName = json['artworkName'];
    height = json['height'];
    width = json['width'];
    sqft = json['sqft'];
    artworkUrl = json['artworkUrl'];

    if (json['locations'] != null) {
      locations = <LocationData>[];
      json['locations'].forEach((v) {
        locations!.add(LocationData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['planServerId'] = planServerId;
    data['planCode'] = planCode;
    data['villageCode'] = villageCode;
    data['villageName'] = villageName;
    data['tehsil'] = tehsil;
    data['stateName'] = stateName;
    data['districtName'] = districtName;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['projectName'] = projectName;
    data['projectId'] = projectId;
    data['noOfPrints'] = noOfPrints;
    data['noOfBalance'] = noOfBalance;
    data['range'] = range;
    data['artworkId'] = artworkId;
    data['artworkName'] = artworkName;
    data['height'] = height;
    data['width'] = width;
    data['sqft'] = sqft;
    data['artworkUrl'] = artworkUrl;

    if (locations != null) {
      data['locations'] = locations!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}

class LocationData {
  String? locateId;
  String? latitude;
  String? longitude;
  int? id;
  bool? isActive;

  LocationData({
    this.locateId,
    this.latitude,
    this.longitude,
    this.id,
    this.isActive,
  });

  LocationData.fromJson(Map<String, dynamic> json) {
    locateId = json['locate_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    id = json['Id'];
    isActive = json['IsActive'];
  }

  Map<String, dynamic> toJson() {
    return {
      'locate_id': locateId,
      'latitude': latitude,
      'longitude': longitude,
      'Id': id,
      'IsActive': isActive,
    };
  }
}




