class LieuPrefereModel {
  String end_address;
  String end_latitude;
  String end_longitude;
  int address_count;

  LieuPrefereModel({
    required this.end_address,
    required this.end_latitude,
    required this.end_longitude,
    required this.address_count,
  });

  factory LieuPrefereModel.fromJson(Map<String, dynamic> json) {
    return LieuPrefereModel(
      end_address: json['end_address'],
      end_latitude: json['end_latitude'],
      end_longitude: json['end_longitude'],
      address_count: json['address_count'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['end_address'] = this.end_address;
    data['end_latitude'] = this.end_latitude;
    data['end_longitude'] = this.end_longitude;
    data['address_count'] = this.address_count;

    return data;
  }
}
