class MapModel {
  String? pickupLatitude;
  String? pickupLongitude;
  String? pickupAddress;

  MapModel({
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupAddress,
  });

  MapModel.fromJson(Map<String, dynamic> json) {
    pickupLatitude = json['latitude'];
    pickupLongitude = json['longitude'];
    pickupAddress = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.pickupLatitude;
    data['longitude'] = this.pickupLongitude;
    data['address'] = this.pickupAddress;
    return data;
  }
}
